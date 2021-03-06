package cron

import (
	log "github.com/Sirupsen/logrus"
	//"github.com/open-falcon/falcon-plus/modules/alarm/g"
	"github.com/open-falcon/falcon-plus/modules/alarm/model"
	"github.com/open-falcon/falcon-plus/modules/alarm/redi"
	//"github.com/toolkits/net/httplib"
	"time"
	"os"
	"os/exec"
)

func ConsumeSms() {
	for {
		L := redi.PopAllSms()
		if len(L) == 0 {
			time.Sleep(time.Millisecond * 200)
			continue
		}
		SendSmsList(L)
	}
}

func SendSmsList(L []*model.Sms) {
	for _, sms := range L {
		SmsWorkerChan <- 1
		go SendSms(sms)
	}
}

func SendSms(sms *model.Sms) {
	defer func() {
		<-SmsWorkerChan
	}()

	//url := g.Config().Api.Sms
	//r := httplib.Post(url).SetTimeout(5*time.Second, 30*time.Second)
	//r.Param("tos", sms.Tos)
	//r.Param("content", sms.Content)
	//resp, err := r.String()
	//if err != nil {
	//	log.Errorf("send sms fail, tos:%s, cotent:%s, error:%v", sms.Tos, sms.Content, err)
	//}
	//log.Debugf("send sms:%v, resp:%v, url:%s", sms, resp, url)

	cmd := exec.Command("/usr/bin/python", "./sendSMS.py", sms.Tos, sms.Content)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		log.Println("==send sms error==>>>>", err)
		log.Errorf("send sms fail, tos:%s, cotent:%s, error:%v", sms.Tos, sms.Content)
	}
	log.Debugf("send sms:%v, resp:%v", sms, err)
}
