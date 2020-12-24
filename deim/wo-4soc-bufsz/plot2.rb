require 'csv'
require 'numo/gnuplot'

titles = ['no logging','8 loggers','16 loggers','24 loggers','32 loggers']
tags = (0..4).map{|i| "#{i}log"}
dt = ['','','dt "-"','dt "."','dt "-."','dt "-"','dt "."','dt "-."']
col = [nil,"red","green","blue"]
pt = [2,8,6,12]

dat = []
[1,2,3].each do |i|
  d = {}
  [1,2].each do |j|
    f = "buf#{j}/buf#{j}-#{tags[i]}/buf#{j}-#{tags[i]}.csv"
    CSV.foreach(f,headers:true) do |row|
      n = row['buffer_num'].to_i
      s = row['buffer_size'].to_i
      e = (d[n] ||= {})
      (e[s] ||= []) << row['throughput[tps]'].to_i*1e-6
    end
  end
  #pp d
  d.keys.sort.each_with_index do |n,j|
    dat << lin = [[],[],w:"lp #{dt[i]} pt #{pt[j]} lc rgbcolor \"#{col[i]}\"", title:" N_L=#{i*8}, N_B=#{n}"]
    d[n].keys.sort.each do |s|
      lin[0] << s
      a = d[n][s]
      lin[1] << a.sort[a.size/2]
    end
  end
end
#p dat

outfile='fig'

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
    set xlabel:"Buffer size [KiB]"
    set ylabel:'"throughput [Mtps]"'
    set title:'Silo YCSB write=100%, 224 threads(worker+logger),
N_L (# of loggers), N_B (# of buffers)'
    set xrange:0..2500
    set yrange:20..40
    #set :nokey
    set key:'outside'
    plot(*dat)
  end
end
