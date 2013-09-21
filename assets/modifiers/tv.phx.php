<?php
return $options;
   /* if(strlen($options )>0) {
	$arr=explode(',',$output);

	foreach($arr as $id){
		$id= (!empty($id) && is_numeric($id)) ? $id: '';
		$result = $modx->getTemplateVar($options, '*', $id); 
		$TV[]= $result['value'];
		}
	return implode(', ',$TV);
	}
	*/
?>