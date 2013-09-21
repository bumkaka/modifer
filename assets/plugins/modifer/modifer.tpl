//<?php
/**
 * Modifer for MODx
 *
 * @category 	plugin
 * @version 	0.1
 * @license 	http://www.gnu.org/copyleft/gpl.html GNU Public License (GPL)
 * @internal    @properties 
 * @internal	@events OnParseDocument 
 * @internal	@modx_category Manager and Admin
 * @internal    @legacy_names Modifer
 * @internal    @installset base
 *
 * @author Bumkaka: use parts of code PHx
 */

$content = $modx->documentOutput;
$replace = array ();
$matches = $modx->getTagsFromContent($content,'[%','%]');
if($matches){
	$variableCount= count($matches[1]);
	for ($i= 0; $i < $variableCount; $i++) {
		if (strpos($matches[1][$i],':') !== false){
			$parts = explode(':',$matches[1][$i]);
			preg_match_all('~\[(\+|\*|\()([^:\+\[\]]+)([^\[\]]*?)(\1|\))\]~s', $matches[1][$i], $match);
			if ($match[0]) {
				$replace[$i] = $matches[0][$i];
				continue;
			}
			$value = Modifer($parts[0],$matches[1][$i]);
			$replace[$i] = $value;
		}
	}
	$content= str_replace($matches[0], $replace, $content);
}
$modx->documentOutput = $content;	


if (!function_exists(Modifer)){

function Modifer($input,$modifiers){
	global $modx;
	$output = $input;
	if (preg_match_all('~:([^:=]+)(?:=`(.*?)`(?=:[^:=]+|$))?~s',$modifiers, $matches)) {
		$modifier_cmd = $matches[1]; // modifier command
		$modifier_value = $matches[2]; // modifier value
		$count = count($modifier_cmd);
		$condition = array();
		for($i=0; $i<$count; $i++) {
			$output = trim($output);
			switch ($modifier_cmd[$i]) {
				#####  Conditional Modifiers 
				case "input":	case "if": $output = $modifier_value[$i]; break;
				case "equals": case "is": case "eq": $condition[] = intval(($output==$modifier_value[$i])); break;
				case "notequals": case "isnot":	case "isnt": case "ne":$condition[] = intval(($output!=$modifier_value[$i]));break;
				case "isgreaterthan":	case "isgt": case "eg": $condition[] = intval(($output>=$modifier_value[$i]));break;
				case "islowerthan": case "islt": case "el": $condition[] = intval(($output<=$modifier_value[$i]));break;
				case "greaterthan": case "gt": $condition[] = intval(($output>$modifier_value[$i]));break;
				case "lowerthan":	case "lt":$condition[] = intval(($output<$modifier_value[$i]));break;
				case "or":$condition[] = "||";break;
				case "and":	$condition[] = "&&";break;
				case "show": 
				$conditional = implode(' ',$condition);
				$isvalid = intval(eval("return (". $conditional. ");"));
				if (!$isvalid) { $output = NULL;}
				case "then":
				$conditional = implode(' ',$condition);
				$isvalid = intval(eval("return (". $conditional. ");"));
				if ($isvalid) { $output = $modifier_value[$i]; }
				else { $output = NULL; }
				break;
				case "else":
				$conditional = implode(' ',$condition);					
				$isvalid = intval(eval("return (". $conditional. ");"));
				if (!$isvalid) { $output = $modifier_value[$i]; }
				break;
				
				case "lcase": case "strtolower": $output = strtolower($output); break;					
				case "ucase": case "strtoupper": $output = strtoupper($output); break;				
				case "htmlent": case "htmlentities": $output = htmlentities($output,ENT_QUOTES,$modx->config['etomite_charset']); break;	
				case "html_entity_decode": $output = html_entity_decode($output,ENT_QUOTES,$modx->config['etomite_charset']); break;				
				case "esc":
				$output = preg_replace("/&amp;(#[0-9]+|[a-z]+);/i", "&$1;", htmlspecialchars($output));
				$output = str_replace(array("[","]","`"),array("&#91;","&#93;","&#96;"),$output);
				break;						
				case "strip": $output = preg_replace("~([\n\r\t\s]+)~"," ",$output); break;
				case "notags": case "strip_tags": $output = strip_tags($output); break;					
				case "length": case "len": case "strlen": $output = strlen($output); break;
				case "reverse": case "strrev": $output = strrev($output); break;
				case "wordwrap": // default: 70
				$wrapat = intval($modifier_value[$i]) ? intval($modifier_value[$i]) : 70;
				$output = preg_replace("~(\b\w+\b)~e","wordwrap('\\1',\$wrapat,' ',1)",$output);
				break;
				case "limit": // default: 100
				$limit = intval($modifier_value[$i]) ? intval($modifier_value[$i]) : 100;
				$output = substr($output,0,$limit);
				break;
				case "str_shuffle": case "shuffle":	$output = str_shuffle($output); break; 	
				case "str_word_count": case "word_count":	case "wordcount": $output = str_word_count($output); break; 	
				
				// These are all straight wrappers for PHP functions
				case "ucfirst":
				case "lcfirst":
				case "ucwords":
				case "addslashes":
				case "ltrim":
				case "rtrim":
				case "trim":
				case "nl2br":					
				case "md5": $output = $modifier_cmd[$i]($output); break;	
				
				
				#####  Special functions 
				case "math":
				$filter = preg_replace("~([a-zA-Z\n\r\t\s])~","",$modifier_value[$i]);
				$filter = str_replace("?",$output,$filter);
				$output = eval("return ".$filter.";");
				break;					
				case "ifempty": if (empty($output)) $output = $modifier_value[$i]; break;
				case "date": $output = strftime($modifier_value[$i],0+$output); break;
				case "set":
				$c = $i+1;
				if ($count>$c&&$modifier_cmd[$c]=="value") $output = preg_replace("~([^a-zA-Z0-9])~","",$modifier_value[$i]);
				break;
				// If we haven't yet found the modifier, let's look elsewhere	
				default:
				
				// modified by Anton Kuzmin (23.06.2010) //
				$snippetName = 'phx:'.$modifier_cmd[$i];
				if( isset($modx->snippetCache[$snippetName]) ) {
					$snippet = $modx->snippetCache[$snippetName];
				} else { // not in cache so let's check the db
					$prfx = $modx->db->config['table_prefix'];
					$sql= "SELECT snippet FROM {$prfx}site_snippets  WHERE {$prfx}site_snippets.name='" . $modx->db->escape($snippetName) . "';";
					$result= $modx->db->query($sql);
					if ($modx->db->getRecordCount($result) == 1) {
						$row= $modx->db->fetchRow($result);
						$snippet= $modx->snippetCache[$row['name']]= $row['snippet'];
						$modx->Log("  |--- DB -> Custom Modifier");
					} else if ($modx->db->getRecordCount($result) == 0){ // If snippet not found, look in the modifiers folder
						$filename = $modx->config['rb_base_dir'] . 'modifiers/'.$modifier_cmd[$i].'.phx.php';
						if (@file_exists($filename)) {
							$file_contents = @file_get_contents($filename);
							$file_contents = str_replace('<'.'?php', '', $file_contents);
							$file_contents = str_replace('?'.'>', '', $file_contents);
							$file_contents = str_replace('<?', '', $file_contents);
							$snippet = $modx->snippetCache[$snippetName] = $file_contents;
							$modx->snippetCache[$snippetName.'Props'] = '';
						}
					}
				}
				$cm = $snippet;
				// end //
				
				ob_start();
				$options = $modifier_value[$i];
				$custom = eval($cm);
				$msg = ob_get_contents();
				$output = $msg.$custom;
				ob_end_clean();	
				break;
			} 
		}
	}	
	
	return $output;
}
}
