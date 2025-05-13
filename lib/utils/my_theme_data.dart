import 'package:flutter/material.dart';
class MyThemeData{
 static Color lightPrimary = const Color(0xFF01122A);
 static Color darkPrimary = const Color(0xFFFDFEFF);

 static ThemeData darkTheme = ThemeData(
  textTheme: const TextTheme(
   titleMedium: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.white,
   ),
      bodyMedium: TextStyle(
       fontSize: 25,
       fontWeight: FontWeight.w700,
       color: Colors.white,
      ),
      headlineSmall: TextStyle(
       fontSize: 20,
       fontWeight: FontWeight.w400,
       color: Color(0xFFA4A4A4),
      )
  ),

  scaffoldBackgroundColor: const Color(0xFF1F3551),
  cardTheme: CardTheme(
   color: const Color(0xFF01122A),
   surfaceTintColor: const Color(0xFF01122A),
   elevation: 18,
   shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
   ),
  ),
  colorScheme: ColorScheme.fromSeed(
   seedColor: const Color(0xFF1F3551),
   primary: const Color(0xFF01122A),
   secondary: const Color(0xFF023A87),
   onPrimary: const Color(0xFFFFFFFF),
   onSecondary: const Color(0xFFFFFFFF),
  ),
  useMaterial3: true,
 );


     static ThemeData lightTheme = ThemeData(
      textTheme: const TextTheme(
          titleMedium: TextStyle(
           fontSize: 20,
           fontWeight: FontWeight.w500,
           color: Colors.white,
          ),
          bodyMedium: TextStyle(
           fontSize: 25,
           fontWeight: FontWeight.w700,
           color: Color(0xFF023A87),
          ),
          headlineSmall: TextStyle(
           fontSize: 20,
           fontWeight: FontWeight.w400,
           color: Color(0xFF47609A),
          )
      ),
      scaffoldBackgroundColor: const Color(0xFF86A5D9),
      cardTheme: CardTheme(
       color: const Color(0xFFFDFEFF),
       surfaceTintColor: const Color(0xFF86A5D9),
       elevation: 18,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
       ),
      ),
      colorScheme: ColorScheme.fromSeed(
       seedColor: const Color(0xFF86A5D9),
       primary: const Color(0xFFFDFEFF),
       secondary: const Color(0xFF023A87),
       onPrimary: const Color(0xFFFFFFFF),
       onSecondary: const Color(0xFFFFFFFF),
      ),
      useMaterial3: true,
     );




}