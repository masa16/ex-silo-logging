require 'csv'
require 'numo/gnuplot'

buffer_num = 4
buffer_size = 512
$node_num = 8

def titles(key)
  dev,n = key
  case n
  when 0
    "no logging"
  else
    #"#{dev}, #{n} loggers"
    "#{n} loggers"
  end
end

def dt(n)
  ['','dt "-"','dt "."','dt "-."','dt "_"'][ls(n)]
end

def ls(n)
  n/$node_num
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
    if row['logger_num'].to_i == 0 ||
        (row['buffer_num'].to_i == buffer_num &&
         row['buffer_size'].to_i == buffer_size)
      e = (d[[dev,row['logger_num'].to_i]] ||= {})
      g = (e[row['thread_num'].to_i] ||= [])
      g << row['throughput[tps]'].to_i*1e-6
    end
  end
end

dat = []
d.keys.each do |key|
  dev,nlog = key
  dat << (l = [[],[],w:"lp ls #{ls(nlog)+1} #{dt(nlog)}", title:titles(key)])
  e = d[key]
  e.keys.sort.each do |n|
    l[0] << n
    a = e[n]
    l[1] << a.sort[a.size/2]
  end
end
pp dat

outfile='wo4-thpt'

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
    set ylabel:'"throughput [Mtps]"'
    set title:"Silo YCSB write=100%, #{buffer_num} buffers #{buffer_size} KiB each"
    set xrange:0..250
    set yrange:0..50
    #set :nokey
    set key:'left'
    plot(*dat)
  end
end
