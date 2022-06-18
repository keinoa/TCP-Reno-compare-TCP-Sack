# TCP-Reno-compare-TCP-Sack
First you need a linux-ubuntu 18.04 environment and download ns2

1. git clone https://github.com/keinoa/TCP-Reno-compare-TCP-Sack.git
2. cd TCP-Reno-compare-TCP-Sack/tcp_congestion_control
3. ns lab11.tcl Reno
4. gnuplot
   set terminal qt (if error, change 'qt' to 'gif')
   plot "cwnd-Reno.tr" notitle with lines
   
