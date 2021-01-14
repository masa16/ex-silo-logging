require 'csv'
require 'numo/gnuplot'

buffer_num = 4
buffer_size = 512

dt = {0=>'',8=>'dt "-"',16=>'dt "."',24=>'dt "-."'}

f = ARGV[0]
d = {}
CSV.foreach(f,headers:true) do |row|
  if row['logger_num'].to_i == 0 ||
      (row['buffer_num'].to_i == buffer_num &&
       row['buffer_size'].to_i == buffer_size)
    e = (d[row['logger_num'].to_i] ||= {})
    g = (e[row['thread_num'].to_i] ||= [])
    g << row['throughput[tps]'].to_i*1e-6
  end
end

def titles(nlog)
  case nlog
  when 0
    'no logging'
  else
    "#{nlog} loggers"
  end
end

dat = []
d.keys.sort.each do |nlog|
  dat << (l = [[],[],w:"lp #{dt[nlog]}", title:titles(nlog)])
  e = d[nlog]
  e.keys.sort.each do |n|
    l[0] << n
    a = e[n]
    l[1] << a.sort[a.size/2]
  end
end

outfile=File.basename(f,'.csv')

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
    set title:"Silo YCSB write=100%, #{buffer_num} buffers #{buffer_size} KiB each
MASSTREE\\_USE=0"
    set xrange:0..60
    #set yrange:0..50
    #set :nokey
    set key:'left'
    plot(*dat)
  end
end
