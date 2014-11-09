#!/usr/bin/env php
<?php
/*
 * This file is part of the Scribe World Application.
 *
 * (c) Scribe Inc. <scribe@scribenet.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

$pattens = [
    'gauge-glist:errors'                       => '^Elements in grown defect list:\s*([0-9]*)',
    'temperature-current_c:temp'             => '^Current Drive Temperature:\s*([0-9]*)',
    'temperature-trip_c:temp'                => '^Drive Trip Temperature:\s*([0-9]*)',
    'gauge-cycle_rated_count:cycle'           => '^Specified cycle count over device lifetime:\s*([0-9]*)',
    'gauge-cycle_current_count:cycle'         => '^Accumulated start-stop cycles:\s*([0-9]*)',
    'gauge-unload_load_rated_count:load'     => '^Specified load-unload count over device lifetime:\s*([0-9]*)',
    'gauge-unload_load_current_count:load'   => '^Accumulated load-unload cycles:\s*([0-9]*)',
    'gauge-hours_powered_up:gen'            => '^\s*number of hours powered up =\s*([0-9\.]*)',
    'gauge-next_smarttest:gen'              => '^\s*number of minutes until next internal SMART test =\s*([0-9\.]*)',
    'gauge-read_ecc_fast:read'               => 'read:\s*([0-9]*)\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-read_ecc_delayed:read'            => 'read:\s*[0-9]*\s*([0-9]*)\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-read_rewrite_reread:read'         => 'read:\s*[0-9]*\s*[0-9]*\s*([0-9]*)\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-read_error_total:read'            => 'read:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*([0-9]*)\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-read_correction_algorithm:read'   => 'read:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*([0-9]*)\s*[0-9\.]*\s*[0-9]*',
    'gauge-read_gigs_processed:read'         => 'read:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*([0-9\.]*)\s*[0-9]*',
    'gauge-read_error_uncorrected:read'      => 'read:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*([0-9]*)',
    'gauge-write_ecc_fast:write'              => 'write:\s*([0-9]*)\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-write_ecc_delayed:write'           => 'write:\s*[0-9]*\s*([0-9]*)\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-write_rewrite_reread:write'        => 'write:\s*[0-9]*\s*[0-9]*\s*([0-9]*)\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-write_error_total:write'           => 'write:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*([0-9]*)\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-write_correction_algorithm:write'  => 'write:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*([0-9]*)\s*[0-9\.]*\s*[0-9]*',
    'gauge-write_gigs_processed:write'        => 'write:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*([0-9\.]*)\s*[0-9]*',
    'gauge-write_error_uncorrected:write'     => 'write:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*([0-9]*)',
    'gauge-verify_ecc_fast:verify'             => 'verify:\s*([0-9]*)\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-verify_ecc_delayed:verify'          => 'verify:\s*[0-9]*\s*([0-9]*)\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-verify_rewrite_reread:verify'       => 'verify:\s*[0-9]*\s*[0-9]*\s*([0-9]*)\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-verify_error_total:verify'          => 'verify:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*([0-9]*)\s*[0-9]*\s*[0-9\.]*\s*[0-9]*',
    'gauge-verify_correction_algorithm:verify' => 'verify:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*([0-9]*)\s*[0-9\.]*\s*[0-9]*',
    'gauge-verify_gigs_processed:verify'       => 'verify:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*([0-9\.]*)\s*[0-9]*',
    'gauge-verify_error_uncorrected:verify'    => 'verify:\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9]*\s*[0-9\.]*\s*([0-9]*)',
];


$collectd_hostname = (string) getenv('COLLECTD_HOSTNAME') ? getenv('COLLECTD_HOSTNAME') : gethostbyaddr('127.0.0.1');
$collectd_interval = (int)    getenv('COLLECTD_INTERVAL') ? getenv('COLLECTD_INTERVAL') : 60;

if (count($argv) <= 1) {
    fwrite(STDERR, "Usage: $argv[0] <disk>[:<driver>,<id>,[...]] <disk>[:<driver>,<id>,[...]] <disk>[:<driver>,<id>,[...]]\n");
    exit(1);
}

$disks   = [];
$drivers = [];
$names   = [];

foreach ($argv as $disk) {
    if ($disk == $argv[0]) { continue; }

    $parts = explode(':', $disk);

    $disks[] = $parts[0];

    if (count($parts) === 2) {
        $names[]   = $parts[1];
        $drivers[] = $parts[1];
    } elseif (count($parts) === 3) {
        $names[]   = $parts[1];
        $drivers[] = $parts[2];
    } else {
        $names[]   = $parts[0];
        $drivers[] = null;
    }
}

do {
    foreach (range(0, count($disks)-1) as $i) {

        if ($drivers[$i] !== null) {
            $driver = '-d '.escapeshellarg($drivers[$i]);
        } else {
            $driver = '';
        }

        $output  = [];
        $return  = 0;
        $command = '/usr/bin/sudo /usr/sbin/smartctl ' . $driver . ' -a ' . escapeshellarg('/dev/' . $disks[$i]);

        exec($command, $output, $return);

        if ($return !== 0) { continue; }

        $output_string = implode("\n", $output);

        foreach ($pattens as $name => $pattern) {
            $matches_return = preg_match('#'.$pattern.'#im', $output_string, $matches);
            if ($matches_return === false) { continue; }
            if (!isset($matches[1])) { continue; }

            $name_parts = explode(':', $name);

            fwrite(STDOUT, "PUTVAL \"$collectd_hostname/smartmon-$name_parts[1]-$names[$i]/$name_parts[0]\" interval=$collectd_interval N:$matches[1]\n");
        }

        fflush(STDOUT);

        sleep($collectd_interval);

    }
} while (true);
