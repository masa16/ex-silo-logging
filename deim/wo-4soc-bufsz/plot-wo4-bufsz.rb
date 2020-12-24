require 'csv'
require 'numo/gnuplot'

thread_num = 224

titles = ['no logging','8 loggers','16 loggers','24 loggers','32 loggers']
tags = (0..4).map{|i| "#{i}log"}
dt = ['','','dt "-"','dt "."','dt "-."','dt "-"','dt "."','dt "-."']
col = [nil,"red","blue","green"]
pt = [2,8,6,12,3,4]
pt = [nil,1,6,2,8,3]

d = {}
%w[wo-4soc-bufsz-pmem.csv].each do |f|
  case f
  when /pmem/; dev='DCPMM'
  when /ssd/; dev='SSD'
  else; dev='no logging'
  end
  CSV.foreach(f,headers:true) do |row|
    if row['thread_num'].to_i + row['logger_num'].to_i == thread_num &&
        row['buffer_num'].to_i < 10
      e = (d[[row['logger_num'].to_i,row['buffer_num'].to_i]] ||= {})
      g = (e[row['buffer_size'].to_f*1.024] ||= [])
      g << row['throughput[tps]'].to_f*1e-6
    end
  end
end
pp d

dat = []
d.keys.each do |key|
  #p key
  nlog,nbuf = key
  ibuf = (Math.log(nbuf)/Math.log(2)).round
  ilog = nlog/8
  #p [ilog,ibuf]
  dat << l = [[],[],w:"lp #{dt[ilog]} pt #{pt[ibuf]} lc rgbcolor \"#{col[ilog]}\"", title:" N_L=#{nlog}, N_B=#{nbuf}"]
  e = d[key]
  e.keys.sort.each do |n|
    l[0] << n
    a = e[n]
    l[1] << a.sort[a.size/2]
  end
end
#pp dat

outfile=File.basename($0,'.rb').sub(/plot-/,'')

%w[png eps emf].each do |term|
  Numo.gnuplot do
    set encoding:"iso_8859_1"
    case term
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
    set xlabel:"Buffer size [KB]"
    set ylabel:'"throughput [Mtps]"'
    set title:'Silo YCSB write=100%, 224 threads(worker+logger),
N_L (# of loggers), N_B (# of buffers)'
    set xrange:0..2500
    set yrange:25..40
    #set :nokey
    set key:'outside'
    plot(*dat)
  end
end
