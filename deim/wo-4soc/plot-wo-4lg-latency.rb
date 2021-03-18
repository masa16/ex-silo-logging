require 'csv'
require 'numo/gnuplot'

$node_num = 8
buffer_num = 4
logger_num = 2 * $node_num
buffer_size = 512

def titles(key)
  dev,n = key
  case n
  when 0
    "no logging"
  else
    #"#{dev}, #{n} buffers"
    "#{n} buffers"
  end
end

def dt(n)
  ['','dt "-"','dt "."','dt "-."','dt "_"'][ls(n)]
end

def ls(n)
  #n/$node_num
  if n>0
    (Math.log(n)/Math.log(2)).round
  else
    0
  end
end

titles = {0=>'no logging',8=>'8 loggers',16=>'16 loggers',24=>'24 loggers'}
dt = {0=>'','DCPMM'=>'dt "."','SSD'=>'dt "_"',24=>'dt "-."'}

d = {}
%w[wo-4soc.csv wo-4soc-pmem.csv].each do |f|
  case f
  when /pmem/; dev='DCPMM'
  when /ssd/; dev='SSD'
  else; dev='no logging'
  end
  CSV.foreach(f,headers:true) do |row|
    if row['logger_num'].to_i > 0 &&
        (row['logger_num'].to_i == logger_num &&
         row['buffer_size'].to_i == buffer_size)
      e = (d[[dev,row['buffer_num'].to_i]] ||= {})
      g = (e[row['thread_num'].to_i] ||= [])
      #g << row['throughput[tps]'].to_i*1e-6
      g << row['durabule_latency'].to_f
    end
  end
end

dat = []
d.keys.each do |key|
  p key
  dev,nbuf = key
  dat << (l = [[],[],w:"lp ls #{ls(nbuf)+1} #{dt(nbuf)}", title:titles(key)])
  e = d[key]
  e.keys.sort.each do |n|
    l[0] << n
    a = e[n]
    l[1] << a.sort[a.size/2]
  end
end
pp dat

outfile='wo4-4lg-latency'

%w[png eps emf pdf].each do |term|
  Numo.gnuplot do
    set encoding:"iso_8859_1"
    case term
    when 'pdf'
      set term:"pdf"
      set output: "#{outfile}.pdf"
    when 'png'
      set term:"pngcairo"
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
    set xlabel:"# of worker threads"
    #set ylabel:'"throughput [Mtps]"'
    set ylabel:'"latency [ms]"'
    #set title:"Silo YCSB write=100%, #{logger_num} loggers, buffer size #{buffer_size} KiB"
    set title:"(b) Persistent Latency"
    set xrange:0..250
    #set yrange:0..600
    set logscale:'y'
    #set :nokey
    set key:'left'
    plot(*dat)
  end
end
