#!/usr/bin/perl -ln
if (/^(\S+)\s*=/) {$name = $1; $x{$name} = [$name]}
    while (/HOST\s*=\s*(.*?)\)/g){ push(@{$x{$name}->[1]}, $1) }
    while (/PORT\s*=\s*(.*?)\)/g){ push(@{$x{$name}->[2]}, $1) }
    if (/SERVICE_NAME\s*=\s*(.*?)\)/){ $x{$name}->[0] = $1 }
    END {while(($k, $v) = each %x){ print join("\t", ($k, $v->[0], map {$v->[1]->[$_].",".$v->[2]->[$_]}(0..$#{$v->[1]}))) }}
            
