#!/bin/bash
set -x #echo on

composer install
php artisan key:generate
php artisan migrate
php-fpm