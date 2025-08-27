--[[
  receiving fax and saving it as tiff image
]]

-- FAXを保存するディレクトリとファイル名
-- このディレクトリはFreeSWITCHが書き込み可能なパーミッションを持っている必要があります。
local fax_file_path = "/tmp/received_fax_" .. session:getVariable("uuid") .. ".tif"

-- スクリプト開始をログに出力
freeswitch.consoleLog("INFO", "== FAX受信スクリプト開始: " .. session:getVariable("uuid") .. " ==\n")

-- セッションに応答
session:answer()

-- rxfaxアプリケーションを実行してFAXを受信
-- 第一引数: 保存先のファイルパス
freeswitch.consoleLog("NOTICE", "FAXの受信を開始します。保存先: " .. fax_file_path .. "\n")
session:execute("rxfax", fax_file_path)

-- FAX受信処理の結果を確認
local fax_success = session:getVariable("fax_success")

if fax_success == "1" then
  -- 受信成功時の処理
  local remote_station_id = session:getVariable("fax_remote_station_id")
  local image_resolution = session:getVariable("fax_image_resolution")
  local image_size = session:getVariable("fax_image_size")
  local bad_rows = session:getVariable("fax_bad_rows")
  local total_pages = session:getVariable("fax_document_total_pages")

  freeswitch.consoleLog("NOTICE", "FAXの受信に成功しました。\n")
  freeswitch.consoleLog("NOTICE", "  - ファイルパス: " .. fax_file_path .. "\n")
  freeswitch.consoleLog("NOTICE", "  - 送信元ID: " .. remote_station_id .. "\n")
  freeswitch.consoleLog("NOTICE", "  - 解像度: " .. image_resolution .. "\n")
  freeswitch.consoleLog("NOTICE", "  - サイズ: " .. image_size .. " bytes\n")
  freeswitch.consoleLog("NOTICE", "  - エラー行数: " .. bad_rows .. "\n")
  freeswitch.consoleLog("NOTICE", "  - 総ページ数: " .. total_pages .. "\n")
else
  -- 受信失敗時の処理
  local fax_result_code = session:getVariable("fax_result_code")
  local fax_result_text = session:getVariable("fax_result_text")

  freeswitch.consoleLog("WARNING", "FAXの受信に失敗しました。\n")
  freeswitch.consoleLog("WARNING", "  - 理由: " .. fax_result_text .. " (Code: " .. fax_result_code .. ")\n")
end

-- スクリプト終了をログに出力
freeswitch.consoleLog("INFO", "== FAX受信スクリプト終了: " .. session:getVariable("uuid") .. " ==\n")

-- セッションを切断
session:hangup()

