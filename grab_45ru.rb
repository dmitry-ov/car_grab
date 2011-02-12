#  Копируем объявления с http://45.ru
# План действий:
# - Заходим на страницу поиска (видим все объявления сайта)
# - Собираем ссылки на объявления c начальной страницы(Ищем в ссылках "advertise/detail/")
# - Переходим на слеующую страницу( если есть ссылка с текстом ">>" кликнем и перейдем дальше)
#   - На каждой последующей странице собираем объявления
# Результат : массив ссылок на объявления о продаже машин  FINAL

$KCODE='u'

require 'iconv'
require 'rubygems'
require 'mechanize'

# require 'csv'


 $mark_auto  = "" 
 $model_auto = ""
 $year_birth_auto = ""
 $price = ""
 $name_foto =  ""
 $url_note = ""

$path_image_folder = '/home/hosting_ovdi/temp_image_folder/'

def get_info note
   agent = WWW::Mechanize.new
    # открыть страницу
   page = agent.get(note.to_s)
   # перекодировать её, что бы ничего нигде не упало )))
   page.encoding = 'UTF-8'
    # Неоходимо получить  -  ( фото - марка/модель - год выпуска - цена )
   content_string = page.content.to_s
   ic = Iconv.new('UTF-8', 'windows-1251')
   content_string = ic.iconv(content_string )

  # Получение модели и марки  авто ------> model_auto , mark_auto
      a = page.title.index("- ").to_i-2
      $model_auto = page.title[0..a]
      $mark_auto = page.title[a+3..page.title.index("-",a+3).to_i-2].strip

  # Получение "года выпуска"  ----->   year_birth_auto
      a = content_string.index("Год выпуска").to_i
      b = content_string.index("</select>",a).to_i
      $year_birth_auto = content_string[b-4..b-1]

  # Получение цены  ----->  price
    a = content_string.index("Цена, руб.").to_i
    b = content_string.index("&nbsp;",a).to_i
    string_with_price = content_string[a..b-1]
   # Избавимся от кавычки внутри цены
  a = string_with_price.index(string_with_price[/[\d]/]) # найдем первую цыфру в строке
  $price = string_with_price[a..string_with_price.size] # вырежем строку 
  # вырежем кавычку, а их может быть 2
  if  $price.index("'")!=nil then  $price.sub!("'","") end  # если была 1-я  кавычка
  if  $price.index("'")!=nil then  $price.sub!("'","") end # если была 2-я  кавычка
  # $price = $price[0..$price.index($price[/\D/])-1] + $price[$price.index($price[/\D/])+1..$price.size]

  # Получение изображения ------>   name_foto
  # <img id="bigimage" src="/_i/sites/45.ru/advertise/image/6548233_1262082907.jpg" border="0"/>
   $name_foto ="no_image.jpg"
   a = content_string.index("><img id=")
      if a!=nil then  
          b = content_string.index("border=",a).to_i-6     # можно найти вторую точку  !!!!! 
          str_img_link = content_string[a..b+3]
          a = str_img_link.index("_i/sites/")
          str_img_link = str_img_link[a..b]
          image = agent.get("http://45.ru/" + str_img_link)
          $name_foto = str_img_link[str_img_link.index("image/").to_i+6..str_img_link.size]
          # $name_foto = rand(1000000).to_s + "_45ru.jpg"
          image.save_as( $path_image_folder + $name_foto)
      end
  #найти слово image, затем выделить из строки имя картинки,  избавиться от генератора чисел
    # Получим ссылку на объявление
  $url_note = note.to_s 

   puts $mark_auto
   puts $model_auto
   puts $year_birth_auto
   puts $price
   puts $name_foto
   puts $url_note
   puts
   
   agent = nil
   page = nil 
end 









def get_notice_from_links_array links # вернет массив строк - ссылок
 ar=[]
  links.each do |l|
    if l.uri.to_s.index("advertise/detail/") then ar<<"http://45.ru"+l.uri.to_s  end
  end
 return ar
end



def get_link_to_next_page links # Вернет ссылку на следующую страницу
  link_to_next_page = ""
      links.each{|link|
        if link.text == ">>"  and  link.uri.to_s.index("advertise").to_i > 0  then        
            link_to_next_page =  "http://45.ru" + link.uri.to_s
            break
        end  
     }
 return link_to_next_page
end






#  правый и левый руль
rul = Array.new(2)
 rul[0] = 'http://45.ru/advertise/search/?type=0&producer%5B1%5D=1&producer%5B2%5D=1&parent=-1&wheeltype=0&fuel%5B0%5D=1&fuel%5B1%5D=1&fuel%5B2%5D=1&fuel%5B3%5D=1&year_from=1960&year_to=2010&probeg_from=&probeg_to=&cost_from=&cost_to=&gearbox=0&valueeng=0&typebody=0&color=-1&period=0&search=%CD%E0%E9%F2%E8'
 rul[1]=  'http://45.ru/advertise/search/?type=0&producer%5B1%5D=1&producer%5B2%5D=1&parent=-1&wheeltype=1&fuel%5B0%5D=1&fuel%5B1%5D=1&fuel%5B2%5D=1&fuel%5B3%5D=1&year_from=1960&year_to=2010&probeg_from=&probeg_to=&cost_from=&cost_to=&gearbox=0&valueeng=0&typebody=0&color=-1&period=0&search=%CD%E0%E9%F2%E8'

notice_links_array=[]   # массив объявлений

rul.each{|link_find_page|  
           agent = WWW::Mechanize.new
            # открыть страницу
             page = agent.get(link_find_page)
             page.encoding = 'UTF-8'
            # ищем ссылки с текстом  advertise/detail/ собираем объявления текущей страницы
             
            # Получим ссылки на объявления с первой страницы
             notice_links_array =  notice_links_array + get_notice_from_links_array(page.links)
            # получим ссылку на следующую страницу
             link_next_page = get_link_to_next_page(page.links)
            # пройдем по всем страницам
                # a=1
             while link_next_page!=""
                # переходим на следующую страницу  - ищем ссылки с текстом ">>"
                 page = agent.get(link_next_page)
                 # добавляем ссылки в масив ссылок на объявления
                 notice_links_array = notice_links_array + get_notice_from_links_array(page.links)
                 # puts get_notice_from_links_array(page.links)
                # можем ли мы перейти на следующую страницу списков объявлений ?
                 link_next_page = get_link_to_next_page(page.links)
                       # puts 'Следующая ссылка ' + link_next_page 
                       # a = a+1
                       # puts a
                 if link_next_page=="" then break end
               end
               # agent = nil # это может удалиться по таймауту
               # page = nil  # и это может удалиться по таймауту            
              #Удалим дубликаты из строки 
                 notice_links_array = notice_links_array.uniq
                 # notice_links_array=notice_links_array[2..3] # укорачиваем список для ускорения отладки !!
}  #rul.each{|link_find_page|         






 # Перебираем ссылки, получаем данные и записываем их в CSV файл
              ic = Iconv.new('UTF-8', 'windows-1251')
                   
              notice_links_array.each{|notice| 
                 begin

                    get_info(notice)

                    $url_note = ic.iconv($url_note)
                    $mark_auto= ic.iconv($mark_auto)
                    $model_auto= ic.iconv($model_auto)
                    $year_birth_auto= ic.iconv($year_birth_auto)
                    $price= ic.iconv($price)
                    $name_foto= ic.iconv($name_foto)
                    $url_note= ic.iconv($url_note)

                   # i = Car.create( :mark_auto => "#{$mark_auto}" , :name_foto => "#{ $name_foto}" , :model_auto => "#{$model_auto}" ,  :year_birth_auto=> "#{$year_birth_auto}" , :price=> "#{$price}" , :url_note=> "#{$url_note}" )
                 
                 rescue 
                 puts $! 
                 end
               } # notice_links_array.each{|notice|

