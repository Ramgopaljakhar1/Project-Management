class ApiConstants {
 static String baseUrl = 'http://210.89.42.219:8083/'; // for test
  //static String baseUrl = 'http://210.89.42.217:8082/';  // base Url for Production
  static String loginApi = 'api/login/';
  static String logOut = 'api/logout/';
  static String addTask = 'api/task_master/';
  static String getTaskList = 'api/task_master/';
  static String ProjectList = 'api/lookup-det/by-code/PRO/';
  static String user_list = 'api/user_list/';
  static String Priority = 'api/lookup-det/by-code/SEV/';
  static String openTaskList = 'api/get_open_task_list/';
  static String myTaskList = 'api/get_my_task_list/';
  static String teamTaskList = 'api/get_team_task_list/';
  static String getFavTaskList = 'api/get_fav_task_list/';
  static String overDueTaskList = 'api/get_overdue_task_list/';
  static String updateFavorite  = 'api/task_master/';
  static String completedOnTime  = 'api/get_completed_ontime_task_list/';
  static String getDelayedTasks  = 'api/get_delayed_task_list/';
  static String getTaskCount  = 'api/get_tasks_count/';
  static String getTasksByAssignee  = 'api/tasks-by-assignee/';
  static String notification  = 'api/get_user_task_notifications/';
  static String assignFilter  = 'api/task_master/';
  static String deleteNotification  = 'api/clear_notifications/';
  static String createReminder  = 'api/create_reminder/';
  static String ticketIDDetails  = 'api/task_list_details/';
  static String sendFcmToken  = 'api/save_fcm_token/';
}