import 'package:flutter/material.dart';
import 'dart:async';

enum OrderStatus { PENDING, COMPLETE }

class Order {
  final int orderId;
  final String type; // Normal or VIP
  OrderStatus status;

  Order(
      {required this.orderId,
      required this.type,
      this.status = OrderStatus.PENDING});
}

class OrderController {
  int _orderIdCounter = 0;
  List<Order> _pendingOrders = [];
  List<Order> _completeOrders = [];
  List<Order> _vipOrders = [];
  List<Bot> _bots = [];
  int _botIdCounter = 0;
  final Function updateUI;

  OrderController({required this.updateUI});

  void newNormalOrder() {
    _orderIdCounter++;
    Order newOrder = Order(orderId: _orderIdCounter, type: 'normal');
    _pendingOrders.add(newOrder);
    _processOrders();
  }

  void newVIPOrder() {
    _orderIdCounter++;
    Order newOrder = Order(orderId: _orderIdCounter, type: 'VIP');
    _vipOrders.add(newOrder);
    _processOrders();
  }

  void increaseBot() {
    _botIdCounter++;
    Bot newBot =
        Bot(botId: _botIdCounter, orderController: this, updateUI: updateUI);
    _bots.add(newBot);
    newBot.start();
    _processOrders();
  }

  void decreaseBot() {
    if (_bots.isNotEmpty) {
      Bot botToRemove = _bots.removeLast();
      botToRemove.stop();
    }
  }

  void _processOrders() {
    for (var bot in _bots) {
      if (!bot.isBusy && (_pendingOrders.isNotEmpty || _vipOrders.isNotEmpty)) {
        if (_vipOrders.isNotEmpty) {
          Order orderToProcess = _vipOrders.removeAt(0);
          bot.processOrder(orderToProcess);
        } else if (_pendingOrders.isNotEmpty) {
          Order orderToProcess = _pendingOrders.removeAt(0);
          bot.processOrder(orderToProcess);
        }
      }
    }
  }

  List<Order> get pendingOrders => [..._vipOrders, ..._pendingOrders];
  List<Order> get completeOrders => _completeOrders;
  List<Bot> get bots => _bots;
}

class Bot {
  final int botId;
  final OrderController orderController;
  bool isBusy = false;
  bool _active = true;
  Timer? _timer;
  int _remainingTime =
      0; // This should hold the remaining processing time for an order
  final Function updateUI;
  Order? currentOrder;

  Bot(
      {required this.botId,
      required this.orderController,
      required this.updateUI});

  void start() {
    _active = true;
  }

  void stop() {
    _active = false;
    _timer?.cancel();
    if (isBusy && currentOrder != null) {
      if (currentOrder!.type == 'VIP') {
        orderController._vipOrders.insert(0, currentOrder!);
      } else {
        orderController._pendingOrders.add(currentOrder!);
      }
      currentOrder = null;
      isBusy = false;
      updateUI();
    }
  }

  void processOrder(Order order) {
    if (!_active) return;
    isBusy = true;
    currentOrder = order;
    _remainingTime = 10; // Assuming a fixed processing time for simplicity
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
        updateUI();
      } else {
        timer.cancel();
        order.status = OrderStatus.COMPLETE;
        orderController._completeOrders.add(order);
        isBusy = false;
        currentOrder = null;
        updateUI();
        if (_active) {
          orderController._processOrders();
        }
      }
    });
  }

  int get remainingTime => _remainingTime; // Getter for remaining time
}

void main() {
  runApp(MyApp());
}

// VIP Order Card
class VipOrderCard extends StatelessWidget {
  final Order order;

  VipOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(
          'VIP - Order ${order.orderId}',
        ),
        leading: Icon(
          Icons.star,
          color: Colors.yellow,
        ),
      ),
    );
  }
}

// Normal Order Card
class NormalOrderCard extends StatelessWidget {
  final Order order;

  NormalOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(
          'Normal - Order ${order.orderId}',
        ),
        leading: Icon(
          Icons.restaurant,
          color: Colors.red,
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late OrderController orderController;

  @override
  void initState() {
    super.initState();
    orderController = OrderController(updateUI: _updateUI);
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  void _updateUI() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontSize: 20),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.yellow,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'McDonalds Order Controller',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(width: 10),
                StreamBuilder(
                  stream: Stream.periodic(Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Text(
                      '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
                      style: TextStyle(color: Colors.black),
                    );
                  },
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          orderController.newNormalOrder();
                        },
                        child: Text('New Normal Order'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          orderController.newVIPOrder();
                        },
                        child: Text('New VIP Order'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildOrderColumn(
                    'Pending Orders', orderController.pendingOrders),
                _buildOrderColumn(
                    'Completed Orders', orderController.completeOrders),
                _buildBotColumn('Bot List', orderController.bots),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          orderController.increaseBot();
                        },
                        child: Text('+ Bot'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          orderController.decreaseBot();
                        },
                        child: Text('- Bot'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderColumn(String title, List<Order> orders) {
    return Container(
      // Wrap the Card with a Container // Set the background color to white
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(height: 8),
          for (var order in orders)
            order.type == 'VIP'
                ? VipOrderCard(order: order)
                : NormalOrderCard(order: order),
        ],
      ),
    );
  }

  Widget _buildBotColumn(String title, List<Bot> bots) {
    return Container(
      // Wrap the Card with a Container // Set the background color to white
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(height: 4),
          ListView.builder(
            shrinkWrap: true,
            itemCount: bots.length,
            itemBuilder: (BuildContext context, int index) {
              Bot bot = bots[index];
              return ListTile(
                title: Text(
                  'Bot ${bot.botId} - Remaining Time: ${bot.remainingTime} seconds',
                ),
                subtitle: bot.currentOrder != null
                    ? Text('Processing Order ${bot.currentOrder!.orderId}')
                    : Text('Idle'),
              );
            },
          ),
        ],
      ),
    );
  }
}
