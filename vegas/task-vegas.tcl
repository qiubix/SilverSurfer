# Create a simulator object
set ns [new Simulator]

# Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red

# Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

# file for saving TCP flow
set f [open tcp.tr w]

# ========== Define nodes and links between them ========== 
#Create nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

# Create links between the nodes
$ns duplex-link $n0 $n1 1000Mb 1ms DropTail
$ns duplex-link $n1 $n2 100Mb 200ms DropTail
$ns duplex-link $n2 $n3 1000Mb 1ms DropTail

# Give node position (for NAM)
$ns duplex-link-op $n0 $n1 orient right
$ns duplex-link-op $n1 $n2 orient right
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n0 $n1 queuePos 0.5

# ========== Setup a TCP connection ========== 
# Set up TCP transmitter
set tcp [new Agent/TCP/Linux]
	#$tcp set class_ 2
	$tcp set window_ 1000000
	$tcp set windowOption_ 8
	$tcp set timestamps_ true
	$ns at 0 "$tcp select_ca vegas"
	$ns attach-agent $n0 $tcp

# Set up TCP receiver
set sink [new Agent/TCPSink/Sack1]
	$sink set ts_echo_rfc1323_ true
	#$tcp set fid_ 1
	$ns attach-agent $n3 $sink

# connect transmitter and receiver
	$ns connect $tcp $sink

# Set up a CBR over TCP connection
# set cbr [new Application/Traffic/CBR]
# 	$cbr attach-agent $tcp
# 	$cbr set type_ CBR
# 	$cbr set packet_size_ 1000
# 	$cbr set rate_ 1000000mb
# 	$cbr set random_ false

# Set up a FTP over TCP connection
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

# =========== DEFINE PROCEDURES =========== 

# procedure for connection tracing 
proc record {} {
  global sink f ns
  set time 0.05
  # odczyt licznika bitów
  set bw [$sink set bytes_]
  # odczyt czasu
  set now [$ns now]
  puts $f "$now [expr $bw/$time*8/1000000]"
  # zerowanie licznika bitow
  $sink set bytes_ 0
  # wywolanie "record" w nastepnym kroku
  $ns at [expr $now+$time] "record"
}

# procedure for closing open files and executing simulation environment
proc finish {} {
	global ns nf f
	close $f
	#Close the NAM trace file
	close $nf
	# draw graph
	exec xgraph -x time -y bandwith tcp.tr -geometry 800x400 &
	#Execute NAM on the trace file
	exec nam out.nam &
	exit 0
}


# =========== SCHEDULE SIMULATION =========== 
#Schedule events for the CBR and FTP agents
$ns at 0 "record"
# $ns at 0 "$cbr start"
# $ns at 10 "$cbr stop"
$ns at 0 "$ftp start"
$ns at 20 "$ftp stop"
 
#change default parameters, all TCP/Linux will see the changes!
$ns at 5 "$tcp set_ca_default_param vegas alpha 40"
$ns at 5 "$tcp set_ca_default_param vegas beta 40"
# confirm the changes by printing the parameter values (optional)
$ns at 5 "$tcp get_ca_default_param vegas alpha"
$ns at 5 "$tcp get_ca_default_param vegas beta"


# change local parameters, only tcp(3) is affected. (optional)
$ns at 10 "$tcp set_ca_param vegas alpha 20"
$ns at 10 "$tcp set_ca_param vegas beta 20"
# confirm the changes by printing the parameter values (optional)
$ns at 10 "$tcp get_ca_param vegas alpha"
$ns at 10 "$tcp get_ca_param vegas beta"

# change local parameters, only tcp(3) is affected. (optional)
$ns at 15 "$tcp set_ca_param vegas alpha 10"
$ns at 15 "$tcp set_ca_param vegas beta 10"
# confirm the changes by printing the parameter values (optional)
$ns at 15 "$tcp get_ca_param vegas alpha"
$ns at 15 "$tcp get_ca_param vegas beta"

#Call the finish procedure after 11 seconds of simulation time
$ns at 21 "finish"

#Run the simulation
$ns run

