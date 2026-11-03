ICONS VERZEICHNIS
=================

Die Ribbon-Buttons referenzieren Icons aus diesem Verzeichnis.
Falls keine eigenen Icons vorhanden sind, entfernt WPF die
fehlenden Bilder einfach (kein Absturz, nur kein Icon sichtbar).

Empfohlene Icon-Sets (kostenlos):
  - https://icons8.com  (PNG, 16x16 / 32x32)
  - https://www.flaticon.com
  - https://materialdesignicons.com

Benötigte Dateinamen (je 16x16 und/oder 32x32 PNG):
  new.png         open.png        save.png        saveas.png
  print.png       paste.png       cut.png         copy.png
  undo.png        redo.png        selectall.png   find.png
  replace.png     bold.png        italic.png      underline.png
  strikethrough.png  subscript.png  superscript.png
  align_left.png  align_center.png  align_right.png  align_justify.png
  list_bullet.png  list_number.png  indent.png  outdent.png
  image.png       datetime.png    zoom_in.png     zoom_out.png

HINWEIS: In der .csproj alle Icons als "Resource" einbinden:
  <ItemGroup>
    <Resource Include="Icons\*.png" />
  </ItemGroup>
(Diese Zeile ist bereits in der .csproj enthalten.)
