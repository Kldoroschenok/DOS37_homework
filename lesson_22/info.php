<?php
echo "Версия ОС сервера: " . php_uname() . "\n";
echo "Тип ОС сервера: " . PHP_OS . "\n";
echo "IP-адрес сервера: " . gethostbyname(gethostname()) . "\n";
?>
