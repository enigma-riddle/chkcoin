require 'clockwork'
require 'ruby_coincheck_client'

include Clockwork

#60分ごとに判定(RANGE=60)
INTERVAL = 60
#ドルコスト平均法で買い付ける価格
SPECIFICYEN = 10000

$hour_average = 1
$last_hour_average = 1

cc = CoincheckClient.new(ENV['API_KEY'],ENV['SECRET_KEY'])
arr_val = [];

every(INTERVAL.second, 'read_ticker') do
  puts 'read_ticker'
  response = cc.read_ticker
  # puts JSON.parse(response.body)
  ticker = JSON.parse(response.body)
  arr_val << ticker['last'].to_f
  # puts arr_val.last
  # puts ticker['last'].to_f
  if arr_val.size >= INTERVAL
    puts arr_val.size
    puts arr_val.inject(:+) / arr_val.size.to_f
    arr_val.shift()
  end
end
# INTERVAL.minutes
every(INTERVAL.minutes, 'buy') do
  $hour_average = arr_val.inject(:+) / arr_val.size.to_f
  puts 'buy'
  puts $hour_average
  puts $last_hour_average
  puts $last_hour_average * 0.99
  response = cc.read_orders
  orders = JSON.parse(response.body)
  puts orders;
  sleep 1
  if orders['orders'] == [] && $hour_average < $last_hour_average * 0.99
    puts 'buyorder'
    downrate = $hour_average.to_f * 0.99
    buy_amount = SPECIFICYEN / downrate
    response = cc.create_orders(rate: downrate, amount: buy_amount, order_type: "buy")
    create_orders = JSON.parse(response.body)
    puts create_orders
  end
  $last_hour_average = $hour_average
end
