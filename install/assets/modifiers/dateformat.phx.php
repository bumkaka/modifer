<?php
//
//usage: [+createdon:dateformat=`%d %B %Y:ru`+]        - manualy set language
//       [+createdon:dateformat=`%d %B %Y:(yams_id)`+] - use with Yams
//

$field = explode(':',$options);
$array1=array ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December ');

switch($field[1]){
	case 'ru':
		$array2=array('Января','Февраля','Марта','Апреля','Мая','Июня','Июля','Августа','Сентября','Октября','Ноября','Декабря');
	break;
	case 'ua':
		$array2= array ('Січня', 'Лютого', 'Березеня', 'Квітня', 'Травня', 'Червня', 'Липня', 'Серпня', 'Вересня', 'Жовтня ', 'листопада', 'Грудня');
	break;
	
	default:
		$array2=array ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December ');
	break;

}

return str_replace($array1,$array2, strftime($field[0], $output) );
?>