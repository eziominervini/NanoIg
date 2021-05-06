set title 'inputNoTrimReads'
set xlabel 'length, bin width = 250'
set ylabel 'number'

binwidth=250
set boxwidth binwidth
bin(x,width) = width*floor(x/width) + binwidth/2.0

set terminal png size 1024,1024
set output './ecoli.1.trimReads.inputNoTrimReads.lg.png'
plot [] [0:] './ecoli.1.trimReads.inputNoTrimReads.dat' using (bin($1,binwidth)):(1.0) smooth freq with boxes title ''

set terminal png size 256,256
set output './ecoli.1.trimReads.inputNoTrimReads.sm.png'
replot
