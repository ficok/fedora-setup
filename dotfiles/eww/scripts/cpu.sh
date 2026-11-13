#!/usr/bin/env bash
# CPU busy percentage over a 1 second sample.
vmstat 1 2 | tail -1 | awk '{print 100 - $15}'
