#!/usr/bin/ruby -wKU

require 're'

include Re

def date_rexp
  delim_re                = re.any("- /.")
  century_prefix_re       = re("19") | re("20")
  under_ten_re            = re("0") + re.any("1-9")
  ten_to_twelve_re        = re("1") + re.any("012")
  ten_and_under_thirty_re = re.any("12") + re.any("0-9")
  thirties_re             = re("3") + re.any("01")
  
  year = century_prefix_re + re.digit.repeat(2)
  month = under_ten_re | ten_to_twelve_re
  day = under_ten_re | ten_and_under_thirty_re | thirties_re
  
  (year.capture(:year) + delim_re + month.capture(:month) + delim_re + day.capture(:day)).all
end

def date_regexp
  /\A((?:19|20)[0-9]{2})[\- \/.](0[1-9]|1[012])[\- \/.](0[1-9]|[12][0-9]|3[01])\z/
end

DATE_REXP = date_rexp
DATE_REXP2 = date_rexp.regexp
DATE_REGEXP = date_regexp

require 'benchmark'

n = 100000
Benchmark.bm do |x|
  x.report("Matching/Regexp:   ") { n.times { DATE_REGEXP =~ "2009/12/28" } }
  x.report("Matching/Re:       ") { n.times { DATE_REXP =~ "2009/12/28" } }
  x.report("Matching/Re.regexp:") { n.times { DATE_REXP2 =~ "2009/12/28" } }
  x.report("Matching/literal:  ") { n.times { /\A((?:19|20)[0-9]{2})[\- \/.](0[1-9]|1[012])[\- \/.](0[1-9]|[12][0-9]|3[01])\z/ =~ "2009/12/28" } }
  x.report("Matching/method:   ") { n.times { date_regexp =~ "2009/12/28" } }
end
puts

n = 10000
Benchmark.bm do |x|
  x.report("Creating/Regexp:   ") { n.times { /\A((?:19|20)[0-9]{2})[\- \/.](0[1-9]|1[012])[\- \/.](0[1-9]|[12][0-9]|3[01])\z/ } }
  x.report("Creating/Re:       ") { n.times { date_rexp } }
end
