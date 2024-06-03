///  @author caoqian
/// @since 2024-04-30 15:34
/// @Description: 对应weather DB中的实体类对象
import 'dart:convert';

class Weather {
  String? location;
  String? temp;
  String? text;
  String? humidity;
  String? date;

  Weather({
    this.location = '101200304',
    this.temp,
    this.text,
    this.humidity,
    this.date,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      location: json['location'] as String?,
      temp: json['temp'] as String?,
      text: json['text'] as String?,
      humidity: json['humidity'] as String?,
      date: json['date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temp': temp,
      'text': text,
      'humidity': humidity,
      'date': date,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}


