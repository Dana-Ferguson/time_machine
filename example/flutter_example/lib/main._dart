import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

String timeMachineText = '';

// todo: make this a proper Flutter example
// note: this only is `main._dart` (vs. `main.dart` to prevent dart_analysis from scanning this file)
Future main() async {
  await example();
  runApp(new MyApp());
}

Future example() async {
  var sb = new StringBuffer();

  try {
    // Run this before -- await TimeMachine.initialize({'rootBundle': rootBundle});
    // runApp() triggers this for you, if you initialize TimeMachine inside your app.
    // your fine
    WidgetsFlutterBinding.ensureInitialized();

    // Sets up timezone and culture information
    await TimeMachine.initialize({'rootBundle': rootBundle});
    sb.writeln('Hello, ${DateTimeZone.local} from the Dart Time Machine!');

    var tzdb = await DateTimeZoneProviders.tzdb;
    var paris = await tzdb["Europe/Paris"];

    var now = SystemClock.instance.getCurrentInstant();

    sb.writeln('\nBasic');
    sb.writeln('UTC Time: $now');
    sb.writeln('Local Time: ${now.inLocalZone()}');
    sb.writeln('Paris Time: ${now.inZone(paris)}');

    sb.writeln('\nFormatted');
    sb.writeln('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm')}');
    sb.writeln('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm')}');

    var culture = await Cultures.getCulture('fr-FR');
    sb.writeln('\nFormatted and French ($culture)');
    sb.writeln('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm', culture)}');
    sb.writeln('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm', culture)}');

    sb.writeln('\nParse French Formatted DateTimeZone');
    // without the 'z' parsing will be forced to interpret the timezone as UTC
    var localText = now
        .inLocalZone()
        .toString('dddd yyyy-MM-dd HH:mm z', culture);

    var localClone = ZonedDateTimePattern
        .createWithCulture('dddd yyyy-MM-dd HH:mm z', culture)
        .parse(localText);
    sb.writeln(localClone.value);
  }
  catch (error, stack) {
    sb.writeln(error);
    sb.writeln(stack);
  }

  timeMachineText = sb.toString();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'TimeMachine Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter TimeMachine Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug paint" (press "p" in the console where you ran
          // "flutter run", or select "Toggle Debug Paint" from the Flutter tool
          // window in IntelliJ) to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              'You have pushed the button this many times:',
            ),
            new Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
            new Text(timeMachineText),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
