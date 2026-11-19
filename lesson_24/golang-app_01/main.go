package main

import (
	"context"
	"fmt"
	"math"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

type config struct {
	pgHost     string
	pgPort     string
	pgDatabase string
	pgUser     string
	pgPassword string
}

var (
	httpRequestsTotal *prometheus.CounterVec
	httpErrorsTotal   *prometheus.CounterVec
	httpResponseTime  *prometheus.HistogramVec
)

type App struct {
	dbPool *pgxpool.Pool
}

func main() {
	cfg := loadConfig()

	initMetrics()

	dbPool, err := pgxpool.Connect(context.Background(),
		fmt.Sprintf("host=%s port=%s dbname=%s user=%s password=%s",
			cfg.pgHost, cfg.pgPort, cfg.pgDatabase, cfg.pgUser, cfg.pgPassword))
	if err != nil {
		panic(fmt.Sprintf("Unable to connect to database: %v", err))
	}
	defer dbPool.Close()

	app := &App{dbPool: dbPool}

	app.initDB()

	// Создание роутера Gin
	r := gin.Default()

	r.Use(app.metricsMiddleware())

	r.GET("/", app.indexHandler)
	r.GET("/error", app.errorHandler)
	r.GET("/generate-load", app.generateLoadHandler)
	r.GET("/metrics", metricsHandler)

	r.Run(":5000")
}

func loadConfig() *config {
	return &config{
		pgHost:     getEnv("PG_HOST", "localhost"),
		pgPort:     getEnv("PG_PORT", "5432"),
		pgDatabase: getEnv("PG_DATABASE", "postgres"),
		pgUser:     getEnv("PG_USER", "postgres"),
		pgPassword: getEnv("PG_PASSWORD", "postgres"),
	}
}

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func initMetrics() {
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total HTTP Requests",
		},
		[]string{"method", "endpoint", "status_code"},
	)

	httpErrorsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_errors_total",
			Help: "Total HTTP Errors",
		},
		[]string{"method", "endpoint", "status_code"},
	)

	httpResponseTime = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_response_time_seconds",
			Help:    "HTTP Response Time",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)

	prometheus.MustRegister(httpRequestsTotal, httpErrorsTotal, httpResponseTime)
}

func (app *App) initDB() {
	_, err := app.dbPool.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS logs (
			id SERIAL PRIMARY KEY,
			endpoint VARCHAR(255),
			method VARCHAR(10),
			status_code INTEGER,
			response_time FLOAT,
			timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		panic(fmt.Sprintf("Unable to create logs table: %v", err))
	}
}

func (app *App) metricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.FullPath()
		if path == "" {
			path = c.Request.URL.Path
		}

		c.Next()

		duration := time.Since(start).Seconds()
		status := c.Writer.Status()
		method := c.Request.Method

		// Обновление метрик
		statusStr := strconv.Itoa(status)
		httpRequestsTotal.WithLabelValues(method, path, statusStr).Inc()
		if status >= 400 {
			httpErrorsTotal.WithLabelValues(method, path, statusStr).Inc()
		}
		httpResponseTime.WithLabelValues(method, path).Observe(duration)

		go func() {
			_, err := app.dbPool.Exec(context.Background(),
				`INSERT INTO logs (endpoint, method, status_code, response_time)
				VALUES ($1, $2, $3, $4)`,
				path, method, status, duration,
			)
			if err != nil {
				fmt.Printf("Error writing to DB: %v\n", err)
			}
		}()
	}
}

func (app *App) indexHandler(c *gin.Context) {
	c.String(http.StatusOK, "Main Page")
}

func (app *App) errorHandler(c *gin.Context) {
	c.String(http.StatusInternalServerError, "Server Error")
}

func (app *App) generateLoadHandler(c *gin.Context) {
	n := 1000000
	if nStr := c.Query("n"); nStr != "" {
		if val, err := strconv.Atoi(nStr); err == nil {
			n = val
		}
	}

	result := 0.0
	for i := 0; i < n; i++ {
		result += float64(i * i)
		result -= float64(i) * 0.5
		result = math.Abs(result)
	}

	_, err := app.dbPool.Exec(context.Background(), "SELECT pg_sleep(0.1)")
	if err != nil {
		c.String(http.StatusInternalServerError, "Database error")
		return
	}

	c.String(http.StatusOK, fmt.Sprintf("Load generated with %d iterations", n))
}

func metricsHandler(c *gin.Context) {
	promhttp.Handler().ServeHTTP(c.Writer, c.Request)
}
