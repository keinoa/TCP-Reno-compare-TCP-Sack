if {$argc != 1} {
	puts"Usage: ns lab11.tcl TCPversion"
	puts"Example:ns lab11.tcl Tahoe or ns lab11.tcl Reno"
	exit
}


set par1 [lindex $argv 0]

#產生一個仿真的對象
set ns [new Simulator]

#tcp parameter
set nf [open $par1/tcp-$par1.nam w]
$ns namtrace-all $nf

#打開一個trace file, 用來記錄封包傳送的過程
set nd [open $par1/tcp-$par1.tr w]
$ns trace-all $nd

#記錄 window size 變化情況
set f0 [open $par1/window_size-$par1.xg w]

#記錄 throughput 變化情況
set f1 [open $par1/throughput-$par1.xg w]

#記錄 queue_length 變化情況
set f2 [open $par1/queue_length-$par1.xg w]

#產生傳送結點，路由器r1,r2和接收結點
set r0 [$ns node]
set r1 [$ns node]
set n0 [$ns node]
set n1 [$ns node]

#建立鏈路
$ns duplex-link $n0 $r0 10Mb 1ms DropTail
$ns duplex-link $r0 $r1 1Mb 4ms DropTail
$ns duplex-link $r1 $n1 10Mb 1ms DropTail

#設置隊列長度爲18個封包大小
set queue 18
$ns queue-limit $r0 $r1 $queue
#$ns queue-limit $r1 $r0 $queue

#根據用戶的設置，指定TCP版本
if {$par1 == "Sack1"} {
	set tcp [new Agent/TCP/Sack1]
} elseif {$par1 == "Fack"} {
	set tcp [new Agent/TCP/Fack]
} elseif {$par1 == "Vegas"} {
	set tcp [new Agent/TCP/Vegas]
} elseif {$par1 == "Newreno"} {
	set tcp [new Agent/TCP/Newreno]
} elseif {$par1 == "Linux"} {
	set tcp [new Agent/TCP/Linux]
} else {
	set tcp [new Agent/TCP/Reno]
}

$ns attach-agent $n0 $tcp

set tcpsink [new Agent/TCPSink]

$ns attach-agent $n1 $tcpsink

$ns connect $tcp $tcpsink

#建立FTP應用程序
set ftp [new Application/FTP]
$ftp attach-agent $tcp

#定義一個結束的程序
proc finish {} {
	global ns nd nf f0 f1 f2 tcp
	#顯示最後的平均吞吐量
	puts [format "average throughput:%.1f Kbps"\
		[expr [$tcp set ack_]*([$tcp set packetSize_])*8/1000.0/10]]
	$ns flush-trace
	#關閉文件
	close $nd
	close $nf 
	close $f0
	close $f1
	close $f2
	exit 0
}

#定義一個記錄的程序
#每格0.01s就去記錄當時的cwnd
proc cwnd {} {
	global ns tcp f0
	
	set time 0.1
	set now [$ns now]
	set window [$tcp set cwnd_]

	puts $f0 "$now $window"

	$ns at [expr $now+$time] "cwnd"
}

#每格0.01s就去記錄當時的throughput
# define some variables for statistics
set tmpLastAck1 -1
proc through_put {} {
	global ns tcp f1 tmpLastAck1
	
	set time 0.1
	set tp_ack [$tcp set ack_]
	set tp_pktSize [$tcp set packetSize_]
	set now [$ns now]
	set throughput [expr (($tp_ack-$tmpLastAck1)*$tp_pktSize / $time) * 8/1000000.0]
	
	puts $f1 "$now $throughput"
	set tmpLastAck1 $tp_ack	

	$ns at [expr $now+$time] "through_put"
}


#每格0.01s就去記錄當時的queue length
set qmonitor [$ns monitor-queue $r0 $r1 [open $par1/qm-$par1.out w]]
proc queue_length {} {
	global ns tcp f2 qmonitor
	
	set time 0.1
	set now [$ns now]
	set len [$qmonitor set pkts_]

	puts $f2 "$now $len"

	$ns at [expr $now+$time] "queue_length"
}

#在0.0s時，開始傳送
$ns at 0.0 "$ftp start"

#在10.0s時，結束傳送
$ns at 10.0 "$ftp stop"

#在0.0s時調用record來記錄TCP的cwnd變化情況
$ns at 0.0 "cwnd"

#在0.0s時調用record來記錄TCP的Throughput變化情況
$ns at 0.0 "through_put"

#在0.0s時調用record來記錄TCP的queue length變化情況
$ns at 0.0 "queue_length"

#在第10.0s時調用finish來結束模擬
$ns at 10.0 "finish"

#執行模擬
$ns run
