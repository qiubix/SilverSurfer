#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red

#Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

#Define a 'finish' procedure
proc finish {} {
        global ns nf
        $ns flush-trace
        #Close the NAM trace file
        close $nf
        #Execute NAM on the trace file
        exec nam out.nam &
        exit 0
}

#Create nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

#Create links between the nodes
$ns duplex-link $n0 $n1 1000mb 1ms DropTail
$ns duplex-link $n1 $n2 100mb 200ms DropTail
$ns duplex-link $n2 $n3 1000mb 1ms DropTail

#Give node position (for NAM)
$ns duplex-link-op $n0 $n1 orient right
$ns duplex-link-op $n1 $n2 orient right
$ns duplex-link-op $n2 $n3 orient right

#Setup a TCP connection
set tcp [new Agent/TCP/Linux]
$tcp set class_ 2
$tcp set window_ 1000
$tcp set timestamps_ true
$ns at 0 "$tcp select_ca vegas"
$ns attach-agent $n0 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
$ns connect $tcp $sink
$tcp set fid_ 1

#Setup a CBR over TCP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $tcp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 100mb
$cbr set random_ false

#Schedule events for the CBR and FTP agents
$ns at 0 "$cbr start"
$ns at 10 "$cbr stop"

#change default parameters, all TCP/Linux will see the changes!
$ns at 3 "$tcp set_ca_default_param vegas alpha 40"
$ns at 3 "$tcp set_ca_default_param vegas beta 40"
# confirm the changes by printing the parameter values (optional)
$ns at 3 "$tcp get_ca_default_param vegas alpha"
$ns at 3 "$tcp get_ca_default_param vegas beta"


# change local parameters, only tcp(3) is affected. (optional)
$ns at 6 "$tcp set_ca_param vegas alpha 20"
$ns at 6 "$tcp set_ca_param vegas beta 20"
# confirm the changes by printing the parameter values (optional)
$ns at 6 "$tcp get_ca_param vegas alpha"
$ns at 6 "$tcp get_ca_param vegas beta"

#Call the finish procedure after 11 seconds of simulation time
$ns at 11 "finish"


#Run the simulation
$ns run

