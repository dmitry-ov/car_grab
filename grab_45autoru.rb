# Копируем объявления с http://45auto.ru
# Составляем массив ссылок на объявления сайта
#  Это была самая последняя версия файла  FINAL

$KCODE='u'

require 'iconv'
require 'rubygems'
require 'mechanize'

# // TO DO   Очистить папку для картинок 
# // TO DO   Проверить отсутствие файла /home/hosting_ovdi/data45auto.sql 
  path_to_folder_with_image = "/home/d/SRC/temp_image_folder/" 
  
  agent = WWW::Mechanize.new
# открыть страницу
  page = agent.get("http://45auto.ru/page/search_result.php?id_marka=0&year_key=0&price_ot=&price_do=&probeg_ot=&probeg_do=&v_motor_ot=&v_motor_do=&sost=0&torg=0&model_id=0&color_id=0&kuzov=0&tip_motor=0&privod=0&kpp=0&rul=0&tamog=0&dop%5B%5D=0&dop%5B%5D=0&dop%5B%5D=0&dop%5B%5D=0&dop%5B%5D=0&dop%5B%5D=0&photo_yes=&stime=0&sort=1&city_list=0&search=%CD%E0%F7%E0%F2%FC+%EF%EE%E8%F1%EA&f_kolvo=#{rand(10000).to_s}")                      
#  перекодировать её, что бы ничего, нигде не упало )))
  page.encoding = 'UTF-8'
# получим массив ссылок "arr" на авто объявления
   arr=[]
   page.links.each{|m| if m.uri.to_s.index("view_bill") then arr << m.uri.to_s end}

# массив ссылок на конкретные объявления машин
  links_auto=[]
  arr.each{|a| links_auto << "http://45auto.ru/page/#{a}"}

 # $str = "INSERT INTO `cars` (`marka`, `model`, `year_birth_auto`, `price`, `name_foto`, `url_note`) VALUES "


 links_auto.each{|notice|

        agent = WWW::Mechanize.new
        # открыть страницу
        page = agent.get(notice)
        #  перекодировать её, что бы ничего нигде не упало )))
        page.encoding = 'UTF-8'
        content_string = page.content.to_s
        ic = Iconv.new('UTF-8', 'windows-1251')
        content_string = ic.iconv(content_string )

        #   ***  Неоходимо получить  -  ( фото - марка/модель - год выпуска - цена )   ****

        # Получение модели авто ------> model_auto
        #        <td nowrap class="style4" width="120">Модель: </td>
        #        <td width="150"><a href = "list_bill.php?id_model=1664">Golf 5</a></td>
        #
        a = content_string.index("Модель:").to_i
        b = content_string.index("</a></td>",a)
        $model_auto = content_string[a..b]

        # укоротим до "list" и найдем
        # первый символ ">"?, за ним начинаеться слово обозначающее марку
        i = $model_auto.index("list").to_i + 1
        a = $model_auto.index(">",i)+1
        b = $model_auto.index("<",a)-1
       $model_auto = $model_auto[a..b]

      #   Получение марки ---> mark_auto
      #<td nowrap class="style4" width="120">Марка: </td>
      #<td width="150"><a href = "list_model.php?id_marka=153">
      #    Volkswagen</a></td>
      #
      a = content_string.index("Марка:").to_i
      b = content_string.index("</a></td>",a)
      $mark_auto = content_string[a..b]


     # укоротим до "list_model" и найдем
      # первый символ ">"?, за ним начинаеться слово обозначающее марку
      i = $mark_auto.index("list").to_i+1
      a = $mark_auto.index(">",i).to_i+3
      b = $mark_auto.index("<",a)-1
      $mark_auto = $mark_auto[a..b].lstrip

      # Получение "года выпуска"  ----->   year_birth_auto
      #          <td nowrap class="style4">Выпуск:</td>
      #          <td>2006 г.</td>
      #
      a = content_string.index("Выпуск:").to_i
      b = content_string.index("г.",a).to_i-2
      $year_birth_auto = content_string[b-3..b].to_i

      #Получение цены  ----->  price
      #
      #           <td nowrap class="style4">Цена: </td>
      #           <td><span class="style6">490000</span> руб.
      #
       a = content_string.index("Цена:").to_i
       b = content_string.index("</span>",a).to_i-1
       string_with_price=content_string[a..b]
      #  укоротим строку, найдем вхождение "style6" и прибавим 8 символов до начала цыфр цены
       $price =  string_with_price[string_with_price.index("style6").to_i+8..b].to_i

      #Получение адреса данного объявления 
      $url_note = notice


      #Получение ссылки на картинку  ----->   name_foto 
        $name_foto ="no_image.jpg"
        a = content_string.index("img/thumb.php")
            if a!=nil then  
                 b = content_string.index(".jpg", a.to_i).to_i
                 string_with_img_link=""
                 string_with_img_link<<content_string[a..(b+3)]
                 string_with_img_link = "http://45auto.ru/page/" + string_with_img_link
                 image = agent.get(string_with_img_link)
                 $name_foto = rand(100000000).to_s + ".jpg" 
                 image.save_as(path_to_folder_with_image + $name_foto)
            end

# Получим все данные 
        puts $name_foto 
        puts $model_auto
        puts $mark_auto
        puts $year_birth_auto
        puts $price
        puts $url_note
   
 # $str << [ "('#{$mark_auto}','#{$model_auto}','#{$year_birth_auto}','#{$price }','#{$name_foto}','#{$url_note}')"].to_s
 # $str << ",".to_s 

# Вставка непосредственно в базу приложения

Car.create( :mark_auto => "#{$mark_auto}" ,
                  :name_foto => "#{ $name_foto}" , 
                  :model_auto => "#{$model_auto}" ,
                  :year_birth_auto=> "#{$year_birth_auto}" ,
                  :price=> "#{$price}" ,
                  :url_note=> "#{$url_note}"
)


 
}


# $str[$str.size-1]=""
 # $str << ";".to_s 

# File.open('/home/hosting_ovdi/data45auto.sql', 'a'){|f| f.write($str+"\n")}

# ic = Iconv.new('UTF-8', 'windows-1251')
# str = File.open('/home/hosting_ovdi/n_file.txt', 'r'){ |file| file.read}
# str = ic.iconv(str)
# File.open('/home/hosting_ovdi/data45auto.sql', 'w'){ |file| file.write str}



