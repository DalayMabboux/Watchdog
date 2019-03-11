{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Lib
  ( watchdog
  )
where

import           Control.Concurrent.Timer
import           Control.Concurrent.Suspend
import           Network.HaskellNet.SMTP
import           Network.HaskellNet.SMTP.SSL
import           System.Environment             ( lookupEnv
                                                , getEnv
                                                )
import           System.IO
import           Data.Maybe                     ( fromMaybe )
import           Control.Monad.Trans.Except
import           Data.Aeson
import           GHC.Generics
import           Network.Wai
import           Network.Wai.Handler.Warp
import           Servant
import           Control.Monad.IO.Class

type ItemApi = "alive" :> Get '[JSON] String

itemApi :: Proxy ItemApi
itemApi = Proxy

mkApp :: TimerIO -> IO Application
mkApp t = return $ serve itemApi (getItems t)

getItems :: TimerIO -> Handler String
getItems t = do
  liftIO (oneShotRestart t)
  return "OK"

data EmailSettings = EmailSettings
  { sender :: String
  , senderPassword :: String
  , receiver :: String
  , smptServer :: String
  } deriving (Show)

-- Throws a runtime error, if one of the variables is not defined
getEmailSettings :: IO EmailSettings
getEmailSettings =
  EmailSettings
    <$> getEnv "EMAIL_SENDER"
    <*> getEnv "EMAIL_SENDER_PASSWORD"
    <*> getEnv "EMAIL_RECEIVER"
    <*> getEnv "SMTP_SERVER"

-- Start a timer T with a duration of D. If there is an event E before the timer ends
-- then the timer will be restarted to the duration D. If there is no event before
-- the end of the timer, then an email will be send to the specified notificator.
sendAlertMail :: EmailSettings -> IO ()
sendAlertMail EmailSettings {..} =
  doSMTPSTARTTLSWithSettings smptServer settings $ \conn -> do
    authSucceeded <- authenticate LOGIN sender senderPassword conn
    if authSucceeded
      then sendPlainTextMail receiver
                             sender
                             "WATCHDOG"
                             "No heartbeat received from WARMS"
                             conn
      else print "failure"
 where
  settings =
    defaultSettingsSMTPSTARTTLS { sslPort = 587, sslLogToConsole = True }

watchdog :: IO ()
watchdog = do
  emailSettings   <- getEmailSettings
  port            <- read . fromMaybe "3000" <$> lookupEnv "PORT"
  healthCheckTime <- read . fromMaybe "45" <$> lookupEnv "HEALTH_CHECK_TIME"
  let settings = setPort port $ setBeforeMainLoop
        (hPutStrLn stderr ("listening on port " ++ show port))
        defaultSettings
  t <- oneShotTimer (sendAlertMail emailSettings) $ mDelay healthCheckTime
  runSettings settings =<< mkApp t
