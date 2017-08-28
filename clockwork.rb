require 'clockwork'
require 'ruby_coincheck_client'

include Clockwork

#指定分ごとに判定
INTERVAL = 15
#ドルコスト平均法で売買する価格
SPECIFICYEN = 10000

$interval_average
$last_interval_average
$buy_flag = true
$sell_flag = true

cc = CoincheckClient.new(ENV['API_KEY'],ENV['SECRET_KEY'])
arr_val = [];

every(INTERVAL.second, 'read_ticker') do
  response = cc.read_ticker
  ticker = JSON.parse(response.body)
  arr_val << ticker['last'].to_f
  if arr_val.size >= 60
    arr_val.shift()
  end
end
# INTERVAL.minutes
every(INTERVAL.minutes, 'trade') do
  $interval_average = arr_val.inject(:+) / arr_val.size.to_f
  $last_interval_average = $interval_average if $last_interval_average.nil?

  puts $interval_average
  puts $last_interval_average
  puts $last_interval_average * 0.99
  puts $last_interval_average * 1.01

  response = cc.read_orders
  orders = JSON.parse(response.body)
  puts orders;
  sleep 1

  if orders['orders'] == [] && $interval_average < $last_interval_average * 0.99 && $buy_flag
    puts 'buyorder'
    downrate = $interval_average.to_f * 0.99
    buy_amount = SPECIFICYEN / downrate
    response = cc.create_orders(rate: downrate, amount: buy_amount, order_type: "buy")
    create_orders = JSON.parse(response.body)
    puts create_orders
    $buy_flag = false
    $sell_flag = true
  end

  if orders['orders'] == [] && $interval_average > $last_interval_average * 1.01 && $sell_flag
    puts 'sellorder'
    uprate = $interval_average.to_f * 1.01
    sell_amount = SPECIFICYEN / uprate
    response = cc.create_orders(rate: uprate, amount: sell_amount, order_type: "sell")
    create_orders = JSON.parse(response.body)
    puts create_orders
    $buy_flag = true
    $sell_flag = false
  end
  $last_interval_average = $interval_average
end

every(3.hour, 'reset_flag') do
  $buy_flag = true
  $sell_flag = true
end
