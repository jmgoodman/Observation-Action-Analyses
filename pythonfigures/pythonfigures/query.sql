SELECT `Zara70`.`Index_Info`.`index`,
`Zara70`.`Index_Info`.`Alignment`,
`Zara70`.`Index_Info`.`Trial`,
`Zara70`.`Index_Info`.`Time`,
`Zara70`.`Trial_Info`.`Object`,
`Zara70`.`Trial_Info`.`Context`
FROM `Zara70`.`Index_Info`
LEFT JOIN `Zara70`.`Trial_Info`
ON `Zara70`.`Index_Info`.`Trial`=`Zara70`.`Trial_Info`.`Trial`;