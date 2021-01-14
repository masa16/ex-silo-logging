require 'csv'
require 'numo/gnuplot'

buffer_num = 4
buffer_size = 512

dt = {0=>'',8=>'dt "-"',16=>'dt "."',24=>'dt "-."'}
dt = {'pmem'=>'','ssd'=>'dt "-"'}

d = {}
ARGV.each do |f|
  case f
  when /ssd/; dev='ssd'
    next
  when /pmem/; dev='pmem'
  else next
  end
  CSV.foreach(f,headers:true) do |row|
    if row['logger_num'].to_i == 0 ||
        (row['buffer_num'].to_i == buffer_num &&
         row['buffer_size'].to_i == buffer_size)
      e = (d[[dev,row['logger_num'].to_i]] ||= {})
      g = (e[row['thread_num'].to_i] ||= [])
      g << row['durabule_latency'].to_f
    end
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

def devcs(dev)
  case dev
  when /pmem/
    'DCPMM'
  when /ssd/
    'SSD'
  end
end

dat = []
d.keys.sort.each do |key|
  dev,nlog = key
  dat << l = [[],[],[],[],w:"yerrorlines ls #{nlog/2} #{dt[dev]}", title:devcs(dev)+', '+titles(nlog)]
  e = d[key]
  e.keys.sort.each do |n|
    a = e[n].sort
    l[0] << n
    l[1] << a[a.size/2]
    l[2] << a[0]
    l[3] << a[-1]
  end
end
p dat

outfile='latency-1socket-1ms-pmem-mimax'

%w[pdf png eps emf].each do |term|
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
        font:["Helvetica",18]
        set output: "#{outfile}.eps"
    when 'emf'
      set term:"emf color enhanced", size:'864,648',
        font:["Helvetica",16]
        set output: "#{outfile}.emf"
    end
    set xlabel:"# of worker threads"
    set ylabel:'"durable latency [ms]"'
    set title:"Silo YCSB write=100%, #{buffer_num} buffers #{buffer_size} KiB each\nepoch\\_time=1ms, 1 socket"
    set xrange:0..60
    #set yrange:0..50
    #set :nokey
    set key:'outside'
    plot(*dat)
  end
end
