require 'csv'
require 'numo/gnuplot'

buffer_num = 4
buffer_size = 512
$node_num = 2
dev = 'ssd'
epoch = '40ms'

def titles(key)
  dev,n = key
  case n
  when 0
    "no logging"
  else
    "#{dev}, #{n} loggers"
  end
end

def dt(n)
  ['','dt "-"','dt "."','dt "-."','dt "_"'][ls(n)]
end

def ls(n)
  n/$node_num
end

def devname(f)
  case f
  when /pmem/; 'DCPMM'
  when /ssd/; 'SSD'
  else; 'no logging'
  end
end

titles = {0=>'no logging',8=>'8 loggers',16=>'16 loggers',24=>'24 loggers'}
dt = {0=>'','DCPMM'=>'dt "."','SSD'=>'dt "_"',24=>'dt "-."'}

d = {}

base="wo1-#{epoch}"

[base+"-pmem.csv",base+"-ssd.csv"].each do |f|
  CSV.foreach(f,headers:true) do |row|
    if row['logger_num'].to_i > 0 &&
        (row['buffer_num'].to_i == buffer_num &&
         row['buffer_size'].to_i == buffer_size)
      e = (d[[devname(f),row['logger_num'].to_i]] ||= {})
      g = (e[row['thread_num'].to_i] ||= [])
      #g << row['throughput[tps]'].to_i*1e-6
      g << row['durabule_latency'].to_f
    end
  end
end

dat = []
d.keys.each do |key|
  p key
  idev,nlog = key
  dat << (l = [[],[],w:"lp ls #{ls(nlog)+1} #{dt[idev]}", title:titles(key)])
  e = d[key]
  e.keys.sort.each do |n|
    l[0] << n
    a = e[n]
    l[1] << a.sort[a.size/2]
  end
end
pp dat

outfile=base+"-latency"

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
    set title:"Epoch=#{epoch}, Silo YCSB write=100%, #{buffer_num} buffers #{buffer_size} KiB each"
    #set logscale:'y'
    #set xrange:0..250
    #set yrange:rng
    #set :nokey
    set key:'left'
    plot(*dat)
  end
end
