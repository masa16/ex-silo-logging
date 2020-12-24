require 'csv'
require 'numo/gnuplot'

log_size = 512*1024
cpu_node = 2

titles = {0=>'no logging',8=>'8 loggers',16=>'16 loggers',24=>'24 loggers'}
dt = {0=>'',8=>'dt "-"',16=>'dt "."',24=>'dt "-."'}
dt = {'mmap'=>'','write'=>'dt "-"'}
#col = {'mmap'=>"red",'write'=>"blue"}
col = {3=>"#ee0000",4=>"#eeaa00",5=>'#dddd00',6=>'#00dd00',8=>'#00dddd',1=>'#0000ff',2=>'#ee00ee'}
pt = {2=>2,3=>8,4=>6,8=>12}
pt = {1=>1,2=>2,3=>3,4=>4,5=>6,6=>5,8=>7}
devs = {'mmap'=>'memcpy','write'=>'write'}

f = ARGV[0]
d = {}
CSV.foreach(f,headers:false) do |row|
  fn = row[0][0..-4]
  node = row[1].to_i
  ls = row[2].to_i
  gs = row[3].to_i
  size = row[4].to_i
  bps = row[5].to_i
  nth = row[6].to_i
  if node == cpu_node && ls == log_size
    e = (d[[fn,nth]] ||= {})
    g = (e[size] ||= [])
    g << bps
  end
end
p d


dat = []
d.keys.sort.each_with_index do |k,i|
  fn,nth = k
  dat << l = [[],[],w:"lp #{dt[fn]} pt #{pt[nth]} lc rgbcolor \"#{col[nth]}\"",
              title:"#{devs[fn]}, N_{thread}=#{nth}"]
  e = d[k]
  e.keys.sort.each do |n|
    l[0] << n
    a = e[n]
    l[1] << a.reduce(:+)/a.size.to_f
    #l[1] << a.sort[a.size.to_f/2]
  end
end

pp dat

outfile=File.basename(f,'.csv')+"-#{cpu_node}"

%w[png eps emf].each do |term|
  Numo.gnuplot do
    set encoding:"iso_8859_1"
    case term
    when 'png'
      set term:"pngcairo",
        font:"Arial,14"
      set output: "#{outfile}.png"
    when 'eps'
      set term:"postscript eps color enhanced", size:'4 inch, 2.5 inch',
        font:["Helvetica",16]
        set output: "#{outfile}.eps"
    when 'emf'
      set term:"emf color enhanced", size:'864,648',
        font:["Helvetica",16]
        set output: "#{outfile}.emf"
    end
    set xlabel:"sync size [B]"
    set ylabel:'write throughput [MB/s]'
    set title:"DCPMM performance (Not-Interleaved),
log\\_size=#{log_size/1024}KiB, node#{cpu_node}->0"
    set logscale:'x'
    set :format, x:'10^{%L}'
    set xrange:5*10**5..10**8
    set yrange:0..1000
    #set :nokey
    set key:'outside'
    plot(*dat)
  end
end
