# Tworzymy obiekt symulatora
 set ns [new Simulator]

# pelne sledzenie symulacji
set nf [open out.nam w]
$ns namtrace-all $nf

# plik do zapis przebiegu TCP
set f [open tcp.tr w]


# 2 wezly + lacze
 set bs [$ns node]
 set br [$ns node]
 $ns duplex-link $bs $br 100Mb 10ms DropTail

# Warstwa 4 ISO/OSI - TCP  nadajnik   
set tcp [new Agent/TCP/Linux]
$tcp set timestamps_ true
$ns at 0 "$tcp select_ca reno"
$tcp set windowOption_ 8
$tcp set window_ 1000000

$ns attach-agent $bs $tcp

# przywiazanie TCP do wezla
 $ns attach-agent $bs $tcp

# Odbiornik TCP
set sink [new Agent/TCPSink/Sack1]
 $sink set ts_echo_rfc1323_ true

# przywiazanie odbiornika do wezla
 $ns attach-agent $br $sink

#nawiazujemy polaczenie
 $ns connect $tcp $sink

# Warstwa aplikacji - tworzymy FTP i podlaczamy do agenta TCP wezla nadawczego
 set ftp [new Application/FTP]
 $ftp attach-agent $tcp
 $ftp set type_ FTP


# sledzenie polaczenia
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

# zamkniecie plikow, uruchomienie programow
proc finish {} {
   global ns nf f
   close $f
   close $nf
   exec  ns-allinone-2.35/xgraph/xgraph -x time -y bandwith tcp.tr -geometry 800x400 &
   exec nam out.nam &
   exit 0
}

# harmonogram symulacji

 $ns at 0 "record"
 $ns at 1 "$ftp start"
 $ns at 10 "$ftp stop"
 $ns at 11 "finish"
 $ns run

