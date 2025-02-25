SKIN=SKIN or {}

function Initialize()
    --memo帳のデータpath
    memotext_data_path=""

    --memoデータ
    memo_name={"new_memo"}
    memo_data={new_memo={}}

    --現在表示しているmemo
    now_memoname="new_memo"
    now_memo=memo_data["new_memo"]

    --memolistを表示しているか(true：表示、false：非表示)
    view_memolist=false

    --memolistの表示ページ
    now_memolist_page=1
    max_memolist_page=1
end

function Update()
    read_memotext_data()
    load_memotext()
end

--テキストファイルから読み込み
function read_memotext_data()
    local memotext_data_file=io.open(memotext_data_path,"r")

    if not memotext_data_file then
        SKIN:Bang("!Log","error read memotext_data","Error")
        return "can't read memotext_data"
    end

    memo_name={}
    memo_data={}

    while true do
        local name=memotext_data_file:read("*l")

        if not name then break end

        table.insert(memo_name,name)
        memo_data[name]={}

        for index=1,5 do
            local memotext=memotext_data_file:read("*l")

            if memotext~="empty" then
                memo_data[name][index]=memotext
            end
        end
    end

    memotext_data_file:close()

    return 0
end

--テキストファイルに書き出し
function save_memotext_data()
    memo_data["new_memo"]={}

    local memotext_data_file=io.open(memotext_data_path,"w")

    if not memotext_data_file then
        SKIN:Bang("!Log","error save memotext_data","Error")
        return "can't save memotext_data"
    end

    for i,name in ipairs(memo_name) do
        memotext_data_file:write(name.."\n")
        
        for index=1,5 do
            if memo_data[name][index]==nil then 
                --入力してないところはemptyとして保存
                memotext_data_file:write("empty\n")
            else
                memotext_data_file:write(memo_data[name][index].."\n")
            end
        end
    end

    memotext_data_file:close()

    return 0
end

--5行のmemoテキストのoptionを再定義
function load_memotext()
    SKIN:Bang("!SetOption","MemoTitle_Meter","Text",(now_memoname=="new_memo" and "新規MEMO" or now_memoname))

    for index=1,5 do
        local MeterName="MemoText_"..index.."_Meter"
        
        SKIN:Bang("!SetOption",MeterName,"Text",(now_memo[index]~="" and now_memo[index] or "Click to Text"))
        SKIN:Bang("!SetOption",MeterName,"LeftMouseUpAction","[!CommandMeasure LuaScript_Measure input_memotext("..index..")]")
    end

    SKIN:Bang("!UpdateMeterGroup","MemoText")
    SKIN:Bang("!Redraw")

    return 0
end

--memo一覧のoptionを再定義
function load_memolist(page_number)
    max_memolist_page=math.ceil(#memo_name/5)

    if now_memolist_page > max_memolist_page then now_memolist_page = max_memolist_page end

    if page_number=="Left" then
        now_memolist_page = now_memolist_page - (now_memolist_page > 1 and 1 or 0)
    elseif page_number=="Right" then
        now_memolist_page = now_memolist_page + (now_memolist_page < max_memolist_page and 1 or 0)
    elseif page_number=="Start" then
        now_memolist_page = 1
    elseif page_number=="end" then
        now_memolist_page = max_memolist_page
    end

    TextDistance=SKIN:GetVariable("TextDistance","10")
    MainTextHeight=SKIN:GetVariable("MainTextFontSize","8")*1.5

    for index=(now_memolist_page-1)*5+1, now_memolist_page*5 do
        --5つづつ表示するときの番号
        local num=(index-1)%5+1

        local MeterName="Memolist_"..num.."_Meter"
        local MeterName_Remove="Memoremove_"..num.."_Meter"

        --mainテキストの縦の表示位置（memoタイトル + memoタイトルの縦幅 + 文字の間隔 * 文字数 + 文字の縦幅 * （文字数 - 1）
        local MeterY=42+20+(TextDistance+MainTextHeight)*num-MainTextHeight

        SKIN:Bang("!SetOption",MeterName,"Hidden",(index>#memo_name and 1 or 0))
        SKIN:Bang("!SetOption",MeterName,"Y",(index>#memo_name and "0" or MeterY))

        --最初の新規作成は削除ボタンを非表示
        SKIN:Bang("!SetOption",MeterName_Remove,"Hidden",((index>#memo_name or index==1) and 1 or 0))
        SKIN:Bang("!SetOption",MeterName_Remove,"Y",(index>#memo_name and "0" or MeterY))

        if index<=#memo_name then
            --memoの内容を表示させるアクション
            local command="[!CommandMeasure LuaScript_Measure view_memo(\'"..memo_name[index].."\')]"

            SKIN:Bang("!SetOption",MeterName,"Text",memo_name[index])
            SKIN:Bang("!SetOption",MeterName,"LeftMouseUpAction",command)

            --削除ボタンのマウスカーソルホバー時のアクション
            local command_MouseOverAction="[!SetOption Memoremove_"..num.."_Meter MeterStyle styleTextMouseOver][!SetOption Memoremove_BackCircle_Meter Y "..MeterY.."][!ShowMeter Memoremove_BackCircle_Meter][!UpdateMeterGroup memoremove][!UpdateMeter Memoremove_BackCircle_Meter][!Redraw]"
            local command_MouseLeaveAction="[!SetOption Memoremove_"..num.."_Meter MeterStyle styleMainText][!HideMeter Memoremove_BackCircle_Meter][!UpdateMeterGroup memoremove][!UpdateMeter Memoremove_BackCircle_Meter][!Redraw]"

            --memoを削除するアクション
            local command_LeftMouseUpAction="[!CommandMeasure LuaScript_Measure memo_remove("..index..")]"

            SKIN:Bang("!SetOption",MeterName_Remove,"MouseOverAction",command_MouseOverAction)
            SKIN:Bang("!SetOption",MeterName_Remove,"MouseLeaveAction",command_MouseLeaveAction)
            SKIN:Bang("!SetOption",MeterName_Remove,"LeftMouseUpAction",command_LeftMouseUpAction)
        end
    end

    SKIN:Bang("!Update")
    SKIN:Bang("!Redraw")

    return 0
end

--5行のmemoテキストの入力欄を移動させるアクションの再定義
function input_memotext(index)
    local TextDistance=SKIN:GetVariable("TextDistance","10")
    local MainTextHeight=SKIN:GetVariable("MainTextFontSize","8")*1.5

    --mainテキストの縦の表示位置（memoタイトル + memoタイトルの縦幅 + 文字の間隔 * 文字数 + 文字の縦幅 * （文字数 - 1）
    local MeterY=42+20+(TextDistance+MainTextHeight)*index-MainTextHeight

    SKIN:Bang("!SetOption","MemoText_InputMeasure","DefaultValue",now_memo[index])
    SKIN:Bang("!SetOption","MemoText_InputMeasure","Y",MeterY)
    
    --入力を完了したときにテキストを変更するアクション
    local command="[!CommandMeasure LuaScript_Measure change_memotext("..index..",\'$UserInput$\')]"
    SKIN:Bang("!SetOption","MemoText_InputMeasure","Command1",command)

    SKIN:Bang("!CommandMeasure","MemoText_InputMeasure","ExecuteBatch 1")

    return 0
end

--memoのタイトルを変更する
function change_memotitle(name)
    if name=="" or name=="new_memo" or now_memoname==name then return 0 end

    --新規作成でないならrenameして元のmemoを削除
    if now_memoname~="new_memo" then
        local index
        for i,value in ipairs(memo_name) do
            if value==now_memoname then index=i end
        end

        table.remove(memo_name,index)
    end

    now_memoname=name
    table.insert(memo_name,name)
    memo_data[name]=now_memo

    SKIN:Bang("!SetOption","MemoTitle_Meter","Text",name)
    SKIN:Bang("!UpdateMeter","MemoTitle_Meter")

    max_memolist_page=math.ceil(#memo_name/5)
    SKIN:Bang("!UpdateMeter","PagePosition_Meter")
    SKIN:Bang("!Redraw")

    return 0
end

--5行のmemoのテキストを変更する
function change_memotext(index,text)
    now_memo[index]=text

    load_memotext()

    return 0
end

--memoの一覧表示を切り替える
function toggle_memolist()
    view_memolist=not view_memolist

    if view_memolist then
        show_memolist()
    else
        hidden_memolist()
    end

    return 0
end

--memoを一覧表示する
function show_memolist()
    SKIN:Bang("!SetOption","Memolist_Button_Meter","Text","X")

    --memoの内容を隠す
    SKIN:Bang("!HideMeterGroup","MemoText")
    SKIN:Bang("!HideMeterGroup","MemoTextIndex")
    SKIN:Bang("!HideMeter","MemoTitle_Meter")

    load_memolist("Start")

    --memo一覧のタイトルを表示
    SKIN:Bang("!ShowMeter","MemoListTitle_Meter")

    --skinのタイトルを横にずらす
    SKIN:Bang("!SetOption","Title_Meter","x","50R")

    --ページ切り替えボタンを表示
    SKIN:Bang("!ShowMeter","LeftPage_Button_Meter")
    SKIN:Bang("!ShowMeter","RightPage_Button_Meter")
    SKIN:Bang("!ShowMeter","PagePosition_Meter")

    SKIN:Bang("!Update")
    SKIN:Bang("!Redraw")

    return 0
end

--memoの内容を表示する
function hidden_memolist()
    SKIN:Bang("!SetOption","Memolist_Button_Meter","Text","O")

    --memoの内容を表示
    SKIN:Bang("!ShowMeterGroup","MemoText")
    SKIN:Bang("!ShowMeterGroup","MemoTextIndex")
    SKIN:Bang("!ShowMeter","MemoTitle_Meter")

    load_memotext()

    --memo一覧を隠す
    SKIN:Bang("!HideMeter","MemoListTitle_Meter")
    SKIN:Bang("!HideMeterGroup","memolist")
    SKIN:Bang("!HideMeterGroup","memoremove")

    --skinのタイトルを横にずらす
    SKIN:Bang("!SetOption","Title_Meter","x","70R")

    --ページ切り替えボタンを隠す
    SKIN:Bang("!HideMeter","LeftPage_Button_Meter")
    SKIN:Bang("!HideMeter","RightPage_Button_Meter")
    SKIN:Bang("!HideMeter","PagePosition_Meter")

    SKIN:Bang("!Update")
    SKIN:Bang("!Redraw")

    return 0
end

--5行のmemoのテキストを表示
function view_memo(name)
    view_memolist=false

    memo_data["new_memo"]={}
    now_memoname=name
    now_memo=memo_data[name]

    hidden_memolist()

    return 0
end

--memoを削除する
function memo_remove(memo_index)
    --選択しているmemoを削除したら選択をnew_memoにする
    if now_memoname==memo_name[tonumber(memo_index)] then
        now_memoname="new_memo"
        now_memo=memo_data["new_memo"]
    end

    table.remove(memo_name,memo_index)
    load_memotext()
    load_memolist("")

    return 0
end

--memo一覧のページ番号
function get_pagenumber()
    return now_memolist_page.." / "..max_memolist_page
end
