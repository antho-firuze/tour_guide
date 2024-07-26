import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  // SUPABASE
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static String supabaseUrl = _Env.supabaseUrl;
  @EnviedField(varName: 'SUPABASE_APIKEY', obfuscate: true)
  static String supabaseApiKey = _Env.supabaseApiKey;
  
  // TURN SERVER (https://www.metered.ca/)
  @EnviedField(varName: 'TURN_APIKEY', obfuscate: true)
  static String turnApiKey = _Env.turnApiKey;
  
  // TURN SERVER (https://www.twilio.com/)
  @EnviedField(varName: 'TWILIO_USERNAME', obfuscate: true)
  static String twilioUsername = _Env.twilioUsername;
  @EnviedField(varName: 'TWILIO_PASSWORD', obfuscate: true)
  static String twilioPassword = _Env.twilioPassword;
  
  // TURN SERVER RYNEST (202.73.24.36)
  @EnviedField(varName: 'RYNEST_TURN_URL', obfuscate: true)
  static String rynesTurnUrl = _Env.rynesTurnUrl;
  @EnviedField(varName: 'RYNEST_USERNAME', obfuscate: true)
  static String rynestUsername = _Env.rynestUsername;
  @EnviedField(varName: 'RYNEST_PASSWORD', obfuscate: true)
  static String rynestPassword = _Env.rynestPassword;
}
