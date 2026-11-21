<?php

/**
 * Static checks for every exercise: lint each PHP file, then load every
 * Workshop class of each exercise directory in a fresh PHP process and
 * instantiate its attributes. This catches syntax errors, missing classes or
 * interfaces, signature mismatches, and invalid Temporal attribute arguments
 * without a Temporal Service or RoadRunner.
 *
 * Run from the track root:  php scripts/check.php   (or: composer check)
 */

declare(strict_types=1);

$root = dirname(__DIR__);
chdir($root);

if ($argc === 3 && $argv[1] === '--load') {
    loadDirectory($argv[2]);
    exit(0);
}

$files = [];
$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator('exercises', FilesystemIterator::SKIP_DOTS));
foreach ($iterator as $file) {
    if ($file->getExtension() === 'php') {
        $files[] = $file->getPathname();
    }
}
foreach (glob('scripts/*.php') as $file) {
    $files[] = $file;
}
sort($files);

$failures = 0;
foreach ($files as $file) {
    exec(sprintf('php -l %s 2>&1', escapeshellarg($file)), $output, $code);
    if ($code !== 0) {
        echo implode("\n", $output), "\n";
        $failures++;
    }
    $output = [];
}
echo 'Linted ', count($files), " files.\n";

if (!is_file('vendor/autoload.php')) {
    fwrite(STDERR, "vendor/ is missing: run composer install to also load every class.\n");
    exit($failures === 0 ? 0 : 1);
}

$directories = array_unique(array_map('dirname', $files));
$directories = array_values(array_filter($directories, static fn(string $dir): bool => str_starts_with($dir, 'exercises/')));
sort($directories);
foreach ($directories as $directory) {
    exec(sprintf('php %s --load %s 2>&1', escapeshellarg(__FILE__), escapeshellarg($directory)), $output, $code);
    if ($code !== 0) {
        echo "FAILED to load {$directory}:\n", implode("\n", $output), "\n";
        $failures++;
    }
    $output = [];
}
echo 'Loaded the classes of ', count($directories), " exercise directories.\n";

if ($failures > 0) {
    fwrite(STDERR, "{$failures} check(s) failed.\n");
    exit(1);
}
echo "PHP static checks passed.\n";

function loadDirectory(string $directory): void
{
    require 'vendor/autoload.php';
    spl_autoload_register(static function (string $class) use ($directory): void {
        $prefix = 'Workshop\\';
        if (str_starts_with($class, $prefix)) {
            $file = $directory . '/' . substr($class, strlen($prefix)) . '.php';
            if (is_file($file)) {
                require_once $file;
            }
        }
    });

    foreach (glob($directory . '/*.php') as $file) {
        $name = 'Workshop\\' . basename($file, '.php');
        $source = (string) file_get_contents($file);
        if (!preg_match('/^(final\s+)?(class|interface)\s+/m', $source)) {
            continue; // scripts such as worker.php and replay.php
        }
        if (!class_exists($name) && !interface_exists($name)) {
            throw new RuntimeException("{$file} does not declare {$name}");
        }
        $class = new ReflectionClass($name);
        foreach ($class->getAttributes() as $attribute) {
            $attribute->newInstance();
        }
        foreach ($class->getMethods() as $method) {
            foreach ($method->getAttributes() as $attribute) {
                $attribute->newInstance();
            }
        }
    }
}
