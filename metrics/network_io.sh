#!/bin/sh

init () {
  if [ -z $NETWORK_IO_INTERFACE ]; then
    if is_osx; then
      NETWORK_IO_INTERFACE="en0"
    else
      NETWORK_IO_INTERFACE="eth0"
    fi
  fi
  readonly __network_io_divisor=$(($INTERVAL * 1024))
}

if is_osx; then
  __network_io_collect () {
    netstat -b -I $NETWORK_IO_INTERFACE | awk '{ print $7" "$10 }' | tail -n 1
  }
else
  __network_io_collect () {
    cat /proc/net/dev | awk -v iface_regex="$NETWORK_IO_INTERFACE:" \
                                    '$0 ~ iface_regex { print $2" "$10 }'
  }
fi

__network_io_calc_kBps() {
  echo $1 $2 | awk -v divisor=$__network_io_divisor \
                '{ printf "%.2f", ($1 - $2) / divisor }'
}

collect () {
  local sample
  sample=$(__network_io_collect)
  if [ ! -z "$__network_io_sample" ]; then
    report "in" $(__network_io_calc_kBps $(echo $sample | awk '{print $1}') \
                                $(echo $__network_io_sample | awk '{print $1}'))
    report "out" $(__network_io_calc_kBps $(echo $sample | awk '{print $2}') \
                                $(echo $__network_io_sample | awk '{print $2}'))
  fi
  __network_io_sample="$sample"
}

docs () {
  echo "Network traffic in kB/s."
  echo "\$NETWORK_IO_INTERFACE="
}