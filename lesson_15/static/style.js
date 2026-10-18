function applyStyles() {
    const css = `
        /* Основные стили */
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f0f2f5;
            color: #333;
            line-height: 1.6;
        }

        #main-header {
            background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
            color: white;
            padding: 2rem;
            text-align: center;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }

        .content {
            display: flex;
            justify-content: center;
            gap: 2rem;
            padding: 2rem;
            flex-wrap: wrap;
        }

        .card {
            background: white;
            border-radius: 12px;
            box-shadow: 0 6px 15px rgba(0,0,0,0.08);
            padding: 1.5rem;
            width: 300px;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 20px rgba(0,0,0,0.12);
        }

        .btn {
            background-color: #4a6ee0;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 50px;
            cursor: pointer;
            font-weight: 600;
            transition: background-color 0.3s;
            margin-top: 1rem;
        }

        .btn:hover {
            background-color: #2e56d0;
        }

        #main-footer {
            text-align: center;
            padding: 1.5rem;
            background-color: #2c3e50;
            color: #ecf0f1;
            margin-top: 2rem;
        }

        /* Адаптивность */
        @media (max-width: 768px) {
            .content {
                flex-direction: column;
                align-items: center;
            }

            .card {
                width: 85%;
            }
        }
    `;


    const styleElement = document.createElement('style');
    styleElement.id = 'dynamic-styles';
    styleElement.textContent = css;


    document.head.appendChild(styleElement);
}


document.addEventListener('DOMContentLoaded', applyStyles);


function toggleDarkMode() {
    const dynamicStyles = document.getElementById('dynamic-styles');
    const isDark = dynamicStyles.textContent.includes('dark-mode');

    if (isDark) {
        dynamicStyles.textContent = dynamicStyles.textContent.replace(
            /\/\* DARK MODE START \*\/[\s\S]*?\/\* DARK MODE END \*\//g,
            ''
        );
    } else {
        dynamicStyles.textContent += `
            /* DARK MODE START */
            body {
                background-color: #121212;
                color: #e0e0e0;
            }

            .card {
                background-color: #1e1e1e;
                box-shadow: 0 6px 15px rgba(0,0,0,0.3);
            }

            #main-footer {
                background-color: #0d0d0d;
            }
            /* DARK MODE END */
        `;
    }
}
