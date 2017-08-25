const cronJob = require('cron').CronJob;
const CoinCheck = require('coincheck');
const coinCheck = new CoinCheck.CoinCheck('ACCESS_KEY', 'API_SECRET');
const params = {
    options: {
        success: (data, response, params) => {
            console.log('success', data);
        },
        error: (error, response, params) => {ß
            console.log('error', error);
        }
    }
};
// 指定秒毎実行
const cronTime = "*/3 * * * * *";

const job = new cronJob({
  //実行したい日時 or crontab書式
  cronTime: cronTime

  //指定時に実行したい関数
  , onTick: () => {
    coinCheck.ticker.all(params);
  }

  //ジョブの完了または停止時に実行する関数
  , onComplete: () => {
    console.log('onComplete!')
  }

  // コンストラクタを終する前にジョブを開始するかどうか
  , start: false
})

//ジョブ開始
job.start();
//ジョブ停止
//job.stop();
