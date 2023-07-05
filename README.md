### [TF2] Round Time

Set maximum round time, remove bonus round time restrictions, and modify how time changes on captures

 * Set setup time
 * Set maximum round time (including king of the hill)
 * Remove bonus round time restrictions
 * Add or set time on point captures
 * Add or set time using command

|cvar|param|description|
|---|:-:|---|
|`sm_time_setup`|**30**|Setup time in seconds, -1 to use default|
|`sm_time_max`|**600**|Maximum round time in seconds, -1 to use default|
|`sm_time_5cp`|(**0** \| 1)|If map is a 5 control point map|
|`sm_time_mode`|(**0** \| 1 \| 2)|How to handle time on capture, 0 = default, 1 = add time, 2 = set time|
|`sm_time_team`|(**0** \| 1 \| 2)|Which team to add or set time to, 0 = both, 1 = capturing team, 2 = other team|
|`sm_time_add`|**60**|Seconds to add on point capture|
|`sm_time_set`|**300**|Seconds to set on point capture|

Admin (`g`) commands

* `sm_addtime <seconds> <team?, 0 = all, 1 = RED, 2 = BLU>`
* `sm_settime <seconds> <team?, 0 = all, 1 = RED, 2 = BLU>`

[![Creative Commons License](https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-nc-sa/4.0/)

Licensed under [CC BY-NC-SA 4.0](https://github.com/KatsuteTF/Round-Time/blob/main/LICENSE)