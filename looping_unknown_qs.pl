#!/usr/bin/perl
use Data::Dumper;
#This program runs gradient descent $loop times for each variation of ($reset_q, $guess_choice).
#gradient hashes creates lots of files and folders. 
#This program opens up the Successes results and calculates the average over the $loop for each one. 

#perl looping.pl freq_pwdset_ovr.txt $m_tot $numloops $B_fraction $num_of_dictionaries $dicts1 $dict2 .. 
#perl looping.pl freq_pwdset_ovr.txt 10 3 0.1 2 freq_d0_ovr.txt freq_d1_ovr.txt 

use IPC::System::Simple qw(system capture);
my $pwdset = $ARGV[0];
$pwdset_name = substr($pwdset, 0, -4);
chomp $pwdset_name;
my $m_tot = $ARGV[1];
my $numloops = $ARGV[2];
my $B_fraction = $ARGV[3];
my $num_of_dictionaries = $ARGV[4]; 

for(my $i=1; $i<=$num_of_dictionaries; $i++){
	$dicts[$i-1] = $ARGV[$i+4];
}


@reset_q = qw(averageqs randomqs bestqs);
@guess_choice = qw(guess_best_from_best guess_best_from_rand guess_best_byQ);

system("mkdir -p $pwdset_name/Successes/Averages/B_frac_$B_fraction");

foreach $reset_q (@reset_q){
	#system("mkdir Averages/$reset_q");
	foreach $guess_choice (@guess_choice){
		open(Out, '>', ''.$pwdset_name.'/Successes/Averages/B_frac_'.$B_fraction.'/average-results-ovr-'.$numloops.'_loops-'.$m_tot.'_guesses-'.$reset_q.'-'.$guess_choice.'.txt') or die "Could not open out.txt: $!";
		#printf Out "i\t N\t count\t avg\n";
		@successes = ();
		@count = ();
		$loop=0;
		while($loop <$numloops){
			system("perl gradient_descents_unknown_qs.pl $reset_q $guess_choice $m_tot $loop $B_fraction $pwdset $num_of_dictionaries @dicts");
			open(FILE, '<', "".$pwdset_name."/Successes/B_frac_$B_fraction/$reset_q/$guess_choice/loop_$loop.txt") or die "Could not open: $!";
			while($line = <FILE>){
				chomp $line;
				($m, $N) = split "\t", $line;
				$successes[$m]+=$N;
				#print "$m, $N, $successes[$m]\n";
				$count[$m]++;
				#print "$m $count[$m]\n";
			}
			
			$loop++;
		}		
		foreach $i (keys @successes){
			unless ($count[$i+1]==0){
				printf Out "%d\t %d\t %d\t %.4f\n", $i+1, $successes[$i+1],$count[$i+1], $successes[$i+1]/$count[$i+1];
			}
		}

	}
}
print "\nLet's start plotting\n\n";
$loop=0;
while($loop <$numloops){
	#system("gnuplot -c plot_L1.gp $B_fraction $pwdset_name $loop");
	foreach $reset_q (@reset_q){
		#system("mkdir Averages/$reset_q");
		foreach $guess_choice (@guess_choice){
			open(lastq_m, '>', "$pwdset_name/QValues/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/lastq_eachm.txt") or die "Could not open last q m: $!";
			printf lastq_m "guess\t";
			for(my $i=1; $i<=$num_of_dictionaries; $i++){
				printf lastq_m "%s\t", $dicts[$i-1];
			}
			printf lastq_m "\n";
			system("tail -qn 1 $pwdset_name/QValues/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/m* >>$pwdset_name/QValues/B_frac_$B_fraction/loop_$loop/$reset_q/$guess_choice/lastq_eachm.txt");
		}
	}
	print "plot Q values for individual m\n";
	plot_Q($m_tot, $B_fraction, $pwdset_name, $loop, $num_of_dictionaries, \@dicts); # plots the Q values. success
	print "plot Q values for gradient descent of first ms\n";
	system("gnuplot -c plot_QValues_mult_m_for_known_qs.gp $m_tot $B_fraction $pwdset_name $loop $num_of_dictionaries");
	print "plot last Q value for first few m\n";
	system("gnuplot -c plot_QValues_mult_m_plot_diff_for_known_qs.gp $m_tot $B_fraction $pwdset_name $loop $num_of_dictionaries");
	print "plot Likelihood\n";
	system("gnuplot -c plot_Likelihood.gp $m_tot $B_fraction $pwdset_name $loop");
	$loop++;
}
print "plot Successes\n";
system("gnuplot -c plot_Successes.gp $m_tot $B_fraction $numloops $pwdset_name");





#Choices to decide here:
#resetting qs:
	#-bestqs
	#-randomqs
	#-averageqs
#choose guess
	#-guess_best_byQ
	#-guess_best_from_best
	#-guess_best_from_rand


#Choices in program:
#guesses $m
#descents $gradient_loop
#stopping conditions.

sub plot_Q{
	my $m= @_[0];
	my $B_frac= @_[1];
	my $pwdset_name= ''.@_[2];
	my $loop= @_[3];
	my $num_dicts= @_[4];
	my $dict = @_[5];
	my @dicts = @$dict;

open(GNUPLOT, "|gnuplot") || die "Couldn't run gnuplot";

print GNUPLOT <<EOF;

set terminal pdf noenhanced color dashed

#check file exists
file_exists(file) = system("[ -f '".file."' ] && echo '1' || echo '0'") + 0

colours = "red green #0000FF"

array_reset_q = "randomqs averageqs bestqs"
array_guess_choice = 'guess_best_byQ guess_best_from_best guess_best_from_rand'

set key out right


#Plot QValues - print one file for each m to show gradient descent
set xlabel "gradient descent loop" font "sans, 17" 
set ylabel "q value estimate" font "sans, 17" 
set yrange [0:]

#we don't know actual values


do for [mval=0:$m-1]{
    do for [i=1:words(array_reset_q)]{
        do for [j=1:words(array_guess_choice)]{
            set output "$pwdset_name/QValues/B_frac_$B_frac/graphs/loop_$loop/m=".mval."/".word(array_reset_q, i)."-".word(array_guess_choice, j)."-m=".mval."-B_frac=$B_frac_-qvalues-large-fake-data.pdf"
            plot for [i=1:$num_dicts] "$pwdset_name/QValues/B_frac_$B_frac/loop_$loop/".word(array_reset_q, i)."/".word(array_guess_choice, j)."/m=".mval.".txt" using 1:i+1 title columnheader w lp pt i+1 dt i+1 lc i+1
		}
    }

} 

        
EOF

close(GNUPLOT);
}


