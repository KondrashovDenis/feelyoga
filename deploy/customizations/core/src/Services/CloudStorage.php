<?php

namespace App\Services;

use Aws\S3\S3Client;
use League\Flysystem\AwsS3V3\AwsS3V3Adapter;
use League\Flysystem\FilesystemAdapter;
use Psr\Http\Message\StreamInterface;
use Vesp\Services\Filesystem;

/**
 * OVERLAY upstream CloudStorage.
 * Добавлена поддержка S3_LOCATION — префикс ключей внутри bucket для изоляции
 * нескольких проектов в одном S3-хранилище.
 *
 * Под Timeweb Cloud: один bucket `vaibkod-secure` шарится между momarus,
 * feelyoga, petparking. Изоляция через префикс (наш — `feelyoga/`).
 * Эквивалент django-storages `location='feelyoga'` (паттерн от инфры Дениса).
 *
 * S3_LOCATION может быть пустой строкой — тогда поведение совпадает с upstream
 * (файлы пишутся в корень bucket'а).
 */
class CloudStorage extends Filesystem
{
    protected S3Client $client;

    protected function getAdapter(): FilesystemAdapter
    {
        $params = [
            'endpoint' => getenv('S3_ENDPOINT'),
            'region' => getenv('S3_REGION'),
            'credentials' => [
                'key' => getenv('S3_KEY'),
                'secret' => getenv('S3_SECRET'),
            ],
        ];
        if (($options = getenv('S3_OPTIONS')) && $options = json_decode($options, true)) {
            $params = array_merge($options, $params);
        }

        $this->client = new S3Client($params);

        // OVERLAY: третий аргумент AwsS3V3Adapter — prefix.
        // Все save/read/delete/list через Flysystem автоматически добавят префикс.
        return new AwsS3V3Adapter($this->client, getenv('S3_BUCKET'), $this->location());
    }

    protected function getRoot(): string
    {
        return '/';
    }

    /**
     * Префикс ключей внутри bucket. Может быть пустым.
     * Гарантируем что заканчивается на '/' если задан — иначе AwsS3V3Adapter
     * странно ведёт себя при concatenation путей.
     */
    protected function location(): string
    {
        $loc = (string)getenv('S3_LOCATION');
        if ($loc === '') {
            return '';
        }
        return rtrim($loc, '/') . '/';
    }

    /**
     * Прямые вызовы S3Client (минуя Flysystem) — добавляем префикс вручную к Key.
     */
    protected function prefixed(string $path): string
    {
        return $this->location() . ltrim($path, '/');
    }

    public function readRangeStream(string $path, int $start, int $end): StreamInterface
    {
        $options = [
            'Bucket' => getenv('S3_BUCKET'),
            'Key' => $this->prefixed($path),
            'Range' => "bytes=$start-$end",
        ];
        $command = $this->client->getCommand('GetObject', $options);

        return $this->client
            ->execute($command)
            ->get('Body');
    }

    public function getDownloadLink(string $path, ?string $filename = null, ?string $timeout = null): string
    {
        $options = [
            'Bucket' => getenv('S3_BUCKET'),
            'Key' => $this->prefixed($path),
            'ResponseContentDisposition' => 'attachment;',
        ];
        if ($filename) {
            $options['ResponseContentDisposition'] .= ' filename="' . $filename . '"';
        }
        if (!$timeout) {
            $timeout = getenv('DOWNLOAD_MEDIA_FROM_S3_TIMEOUT') ?: '+6 hours';
        }
        $command = $this->client->getCommand('GetObject', $options);
        $request = $this->client->createPresignedRequest($command, $timeout);

        return (string)$request->getUri();
    }

    public function getStreamLink(string $path, ?string $timeout = null): string
    {
        $options = [
            'Bucket' => getenv('S3_BUCKET'),
            'Key' => $this->prefixed($path),
        ];
        if (!$timeout) {
            $timeout = getenv('DOWNLOAD_MEDIA_FROM_S3_TIMEOUT') ?: '+6 hours';
        }
        $command = $this->client->getCommand('GetObject', $options);
        $request = $this->client->createPresignedRequest($command, $timeout);

        return (string)$request->getUri();
    }

    public function setBucketCorsRules(array $rules = []): bool
    {
        if (!$rules) {
            $rules = [
                'CORSRules' => [
                    [
                        'AllowedMethods' => ['GET'],
                        'AllowedOrigins' => ['*'],
                        'AllowedHeaders' => ['*'],
                        'ExposeHeaders' => [],
                        'MaxAgeSeconds' => 3600,
                    ],
                ],
            ];
        } elseif (!isset($rules['CORSRules'])) {
            $rules['CORSRules'] = $rules;
        }

        $response = $this->client->putBucketCors([
            'Bucket' => getenv('S3_BUCKET'),
            'CORSConfiguration' => $rules,
        ]);

        return $response->get('@metadata')['statusCode'] === 200;
    }
}
