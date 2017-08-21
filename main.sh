#PARAMETERS
#-PICTURE
WIDTH=200
HEIGHT=20
XCOORD=65
YCOORD=70
QUALITY=20 #100 is max compression (worse quality)
PIC_OUTPUT_NAME="currentPic.png"
PIC_RESCALE=1000 #Make image 10 times larger for tesseract
BINARY_THRESHOLD=50

#-MOUSE NAVIGATION
DELTA_X=100
DELTA_Y=50
INITIAL_X=200
INITIAL_Y=200
MAX_X=1000
MAX_Y=750

#-TRANSCRIPTION
TRANSCRIPT="transcription.txt"
x=$INITIAL_X
y=$INITIAL_Y
TARGET_TEXT="Smelt Furnace"
rm $TRANSCRIPT

#-WORLD NAVIGATION

#-INTERFACE COORDINATES

#--SMITHING

#---UI COORDINATES
BRONZE_X=118
BRONZE_Y=640
IRON_X=222
IRON_Y=640

#---PARAMETERS
TIME_PER_BAR=3 #seconds

#-PROCESS
smithing="IRON"


#-MATCHING
MATCH_MINIMUM=79

#DATA
INVENTORY='' #make array

main(){

local x_intervals=$(divide $(subtract $MAX_X $INITIAL_X ) $DELTA_X)
x_intervals=$(floor $x_intervals)
local y_intervals=$(divide $(subtract $MAX_Y $INITIAL_Y ) $DELTA_Y)
y_intervals=$(floor $y_intervals)


for i in `seq 0 $x_intervals`
do
  x=$(add $INITIAL_X $(multiply $i $DELTA_X) ) 
  echo -ne "$i/$x_intervals\r"  
  for j in `seq 0 $y_intervals`
  do
  y=$(add $INITIAL_Y $(multiply $j $DELTA_Y) ) 
  #echo "MOVING TO: $x $y"
  xdotool mousemove $x $y
   #CAPTURE IMAGE
  #echo "Analyzing screen"
  local imageName=$(analyzeScreen)
   #CALL IMAGE PROCESSING
  #echo "Preprocessing image"
  preprocessImage
   #TRANSCRIBE IMAGE INTO TEXT
  local transcription=$(transcribeImage)
  
  #RATE MATCH WITH TARGET TEXT
  local matchRating=$(stringMatch $transcription)  
  
  #OUTPUT TO FILE
  echo "x: $x y: $y" >> $TRANSCRIPT
  echo $transcription >> $TRANSCRIPT
  echo "MATCH: $matchRating" >> $TRANSCRIPT
  echo " " >> $TRANSCRIPT

  local matchSuccess=`echo "$matchRating > $MATCH_MINIMUM" | bc -l`
  echo $matchRating $MATCH_MINIMUM $matchSuccess
  #MATCH SUCCESS SCENARIO
  if [ $matchSuccess -eq 1 ];then
    echo "MATCH SUCCESS"
    #while true
    #do
    smelt
    #echo "doing stuff"
    #sleep 1
    #done
  fi
  done
done
}

pause(){
  while true
  do
    echo "paused..."
    sleep 30
  done
}
smelt(){
 # sleep 5
  xdotool click 1
  local bar_icon_x=0
  local bar_icon_y=0
  if [ "$smithing" == "BRONZE" ];then
    bar_icon_x=$BRONZE_X
    bar_icon_y=$BRONZE_Y
  elif [ "$smithing" == "IRON" ];then
    bar_icon_x=$IRON_X
    bar_icon_y=$IRON_Y  
  fi 
  sleep 2 # wait until you arrive at the furnace
  #Move cursor to the desired bar
  xdotool mousemove $bar_icon_x $bar_icon_y
  xdotool click 3
  xdotool mousemove $bar_icon_x 700 #coordinates for Smelt x number of bars opt
  sleep 1
  xdotool click 1
  sleep 1

  local bar_quantity=28 # TODO check inventory array

  xdotool type 28
  xdotool key KP_Enter
  local sleep_duration=$(multiply 28 $TIME_PER_BAR)
  echo "smelting..." >&2
  sleep $sleep_duration
  pause
}
stringMatch(){
  local transcription=$1
  local matchRating=0
  matchRating=`python fuzzyMatch.py $transcription $TARGET_TEXT`
  echo $matchRating  
}
transcribeImage(){
  tesseract $PIC_OUTPUT_NAME tmp 1>/dev/null 2>&1
  cat tmp.txt
}
preprocessImage(){
  convert -resize ${PIC_RESCALE}% $PIC_OUTPUT_NAME $PIC_OUTPUT_NAME
  convert $PIC_OUTPUT_NAME -type Grayscale $PIC_OUTPUT_NAME
  #convert $PIC_OUTPUT_NAME -threshold ${BINARY_THRESHOLD}% $PIC_OUTPUT_NAME
}
analyzeScreen(){
  #Note: Maybe name images according to screen position, and world location
  local imageName=$(date +%Y%m%d-%H%M%S).png
  import -window root -crop ${WIDTH}x${HEIGHT}+$XCOORD+$YCOORD -quality $QUALITY $PIC_OUTPUT_NAME
  echo $imageName
}


#BEGINNING OF MATH FUNCTIONS-----------------------------------------


#returns $1+$2
add(){
  local term1=$1
  local term2=$2
  local Sum=`echo "$term1 + $term2" | bc -l`
  echo $Sum
}

#returns $1-$2
subtract(){
  local term1=$1
  local term2=$2
  local difference=`echo "$term1 - $term2" | bc -l`
  echo $difference
}

#returns $1/$2
divide(){
  local dividend=$1
  local divisor=$2
  local quotient=`echo "$dividend / $divisor" | bc -l`
  echo $quotient
}

#returns $1*$2
multiply(){
  local factor1=$1
  local factor2=$2
  local product=`echo "$factor1 * $factor2" | bc -l`
  echo $product
}

#returns floor of $1
floor(){
  local float=$1
  local integer=$( printf "%0.f" $float )
  echo $integer
}


#END OF MATH FUNCTIONS-----------------------------------------------


#LOOP FOREVER--------------------------------------------------
while true
do
sleep 1
main andrew
done
#--------------------------------------------------------------
