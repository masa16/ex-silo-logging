require 'csv'
require 'numo/gnuplot'

buffer_num = 4
logger_num = 16
buffer_size = 512

def titles(n)
  case n
  when 0
    "no logging"
  else
    "#{n} buffers"
  end
end

def dt(n)
  ['','dt "-"','dt "."','dt "-."','dt "_"'][ls(n)]
end

def ls(n)
  n > 0 ? (Math.log(n)/Math.log(2)).to_i : 0
end

titles = {0=>'no logging',8=>'8 loggers',16=>'16 loggers',24=>'24 loggers'}
dt = {0=>'',8=>'dt "-"',16=>'dt "."',24=>'dt "-."'}

f = ARGV[0]
d = {}
CSV.foreach(f,headers:true) do |row|
  if row['logger_num'].to_i == 0 ||
      (row['logger_num'].to_i == logger_num &&
       row['buffer_size'].to_i == buffer_size)
    e = (d[row['buffer_num'].to_i] ||= {})
    g = (e[row['thread_num'].to_i] ||= [])
    g << row['throughput[tps]'].to_i*1e-6
  end
end
pp d

dat = []
d.keys.sort.each do |nbuf|
  dat << (l = [[],[],w:"lp ls #{ls(nbuf)+1} #{dt(nbuf)}", title:titles(nbuf)])
  e = d[nbuf]
  e.keys.sort.each do |n|
    l[0] << n
    a = e[n]
    l[1] << a.sort[a.size/2]
  end
end

outfile=File.basename(f,'.csv')+'-fig3'

%w[png eps emf].each do |term|
  Numo.gnuplot do
    set encoding:"iso_8859_1"
    case term
    when 'png'
      set term:"pngcairo"
      set output: "#{outfile}.png"
    when 'eps'
      set term:"postscript eps color enhanced", size:'4 inch, 2.5 inch',
        font:["Helvetica",18]
        set output: "#{outfile}.eps"
    when 'emf'
      set term:"emf color enhanced", size:'864,648',
        font:["Helvetica",16]
        set output: "#{outfile}.emf"
    end
    set xlabel:"# of worker threads"
    set ylabel:'"throughput [Mtps]"'
    set title:"Silo YCSB write=100%, #{logger_num} loggers, buffer size #{buffer_size} KiB"
    #set logscale:'y'
    set xrange:0..250
    set yrange:0..50
    #set :nokey
    set key:'left'
    plot(*dat)
  end
end
