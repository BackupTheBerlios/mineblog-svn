#!/bin/bash

# erstmal den originalen IFS sichern
oldIFS=$IFS

# und ein paar variablen belegen
# im CONTENT_DIR liegen die dateien
CONTENT_DIR="/var/www/mineblog_content"
# CONTENT_DIR_WWW ist ein web-server-relativer pfad zum content verzeichnis
CONTENT_DIR_WWW="../mineblog_content"
# im TEMPLATE_DIR vorlagen für header, footer etc
TEMPLATE_DIR="./templates"

# den header ausgeben
cat < ${TEMPLATE_DIR}/head.html

# das content-verzeichnis in die CONTENT_FILES variable einlesen
CONTENT_FILES=`ls -1 --sort=t ${CONTENT_DIR}`

# splitchar auf newline setzen und die einzelnen dateien durchgehen
IFS=$'\n'  
for ONE_FILE in ${CONTENT_FILES};
do
  # als erstes mal die basisattribute (owner, timestamp) holen und in
  # variablen packen
  FILE_OWNER=`stat -c %U ${CONTENT_DIR}/${ONE_FILE}`;
  TIMESTAMP_UNC=`stat -c %y ${CONTENT_DIR}/${ONE_FILE} | cut -d" " -f1,2`;
  FILE_DATE=${TIMESTAMP_UNC%$' '*}
  FILE_TIME=${TIMESTAMP_UNC#$FILE_DATE$' '}
  FILE_TIME=${FILE_TIME%":"*}
  # die verschiedenen dateitypen/endungen prüfen und dateityp in
  # variable speichern
  # das ginge natürlich (und korrekter) über `file`, aber so gehts schneller
  #
  # mögliche dateitypen:
  #  1: Text (html oder nicht ;)
  #  2: JPEG
  BASENAME_TXT=`basename ${CONTENT_DIR}/${ONE_FILE} .txt`;
  BASENAME_JPG=`basename ${CONTENT_DIR}/${ONE_FILE} .jpg`;
  if [ ${BASENAME_TXT} != ${ONE_FILE} ];
  then
    FILETYPE=1
    BASENAME_REAL=${BASENAME_TXT}
  elif [ $BASENAME_JPG} != ${ONE_FILE} ];
  then
    FILETYPE=2
    BASENAME_REAL=${BASENAME_JPG}
  fi;

  # hier kann schon mal der header des beitrags ausgegeben werden...
  echo "<h2>$BASENAME_REAL</h2>";
  echo '<div class="cont_stats">';
  echo "Beitrag von $FILE_OWNER, geschrieben am $FILE_DATE um $FILE_TIME.";
  echo "</div>";

  # den content-bereich einleiten
  echo '<div class="content">';

  # dann die datei an sich verarbeiten
  # Textdateien
  if [ ${FILETYPE} -eq 1 ];
  then
    
    # hier wird einfach der text eingeschoben
    cat < content/${ONE_FILE};

  # JPEGs/Grafiken
  elif [ ${FILETYPE} -eq 2 ];
  then 
 
    # zunächst die bildgröße bestimmen (mit imagemagick -> identify)
    PIC_IDENTITY_STRING=`identify ${CONTENT_DIR}/${ONE_FILE}`

    # aus dem identity string alles außer der größe rausmatchen
    PIC_WIDTH=${PIC_IDENTITY_STRING%%x*} 
    PIC_WIDTH=${PIC_WIDTH##*$' '}
    PIC_HEIGHT=${PIC_IDENTITY_STRING##*x}
    PIC_HEIGHT=${PIC_HEIGHT%%$' '*}
 
    # und schließlich den image-tage einbauen
    echo "<img src='${CONTENT_DIR_WWW}/${ONE_FILE}' alt='Bild: ${BASENAME_REAL}' width='${PIC_WIDTH}' height='${PIC_HEIGHT}' />"

  fi;

  # und den content-bereich beenden
  echo "</div>";

done;

# zum schluß den footer feeden, IFS rekonstruieren und exit 0
cat < ${TEMPLATE_DIR}/foot.html
IFS=$oldIFS
exit 0
