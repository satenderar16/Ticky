// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart';
// import 'package:quthon/Auth/auth_notifier.dart';
// import 'package:quthon/Auth/http_manager.dart';
// import 'package:quthon/Contest/contest_model.dart';
// import 'package:quthon/Models/leaderboard_model.dart';
// import 'package:quthon/Models/register_models.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:quthon/Repository/contest_repository.dart';

// final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>(
//   (ref) => RegisterNotifier(ref: ref),
// );

// class RegisterNotifier extends StateNotifier<RegisterState> {
//   final Ref ref;
//   // we can also use this in state by it is just don't play any role in ui just to track the next screen:
//   RegisterDetailModel? selectedRegister;
//   RegisterNotifier({required this.ref, this.selectedRegister})
//     : super(const RegisterState(registered: <RegisterDetailModel>[])) {
//     _init();
//   }

//   // init function to intiate when registerNotifier build:
//   void _init() async {
//     getRegisterContest();
//   }

//   /// Set the registered user
//   void setRegistered(List<RegisterDetailModel> registration) {
//     state = state.copyWith(registered: registration);
//   }

//   /// Set loading
//   void setLoading(bool loading) {
//     state = state.copyWith(loading: loading);
//   }

//   /// Set error
//   void setError(String? error) {
//     state = state.copyWith(error: error);
//   }

//   // this help us to track all the screen depends on selected value of register:
//   void setSelectedRegister(RegisterDetailModel? value) {
//     selectedRegister = value;
//   }

//   /// Get index for a registered.id

//   int? getRegisterIndex(String id) {
//     return state.registerIdMap[id];
//   }

//   int getCurrentRegisterIndex() {
//     return state.registerIdMap[selectedRegister!.contest.id]!;
//   }

//   /// Clear all indices
//   void clearRegisterIds() {
//     state = state.copyWith(registerIdMap: {});
//   }

//   // ---------------------------------------------------HANDLING. APIS ------------------------------------->

//   // get register from api and update map and list, use that list from state reflex on UI:
//   Future<List<RegisterDetailModel>> getRegisterContest({
//     bool refresh = false,
//     int offset = 0,
//     int limit = 30,
//   }) async {
//     try {
//       if (!refresh) {
//         state = state.copyWith(loading: true);
//       }

//       final responseBody = await ContestRepository.getParticipateContestList();
//       final List<dynamic> data = await jsonDecode(responseBody)['data'];

//       final registered =
//           data
//               .map(
//                 (e) => RegisterDetailModel.fromJson(e as Map<String, dynamic>),
//               )
//               .toList();
//       final registerIdMap = {
//         for (int i = 0; i < registered.length; i++) registered[i].contest.id: i,
//       };
//       state = state.copyWith(
//         loading: false,
//         registered: registered,
//         registerIdMap: registerIdMap,
//       );

//       // debugPrint(register[0].toJson().toString());

//       return registered; // we can improve this by return limit value from the repo instead of depending on length as when is less then 1 it could be infinite loop:
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//       debugPrint('register fetch called and catched');
//       rethrow;
//     }
//   }

//   Future<void> silentRefreshRegisterContest() async {
//     try {
//       await getRegisterContest(refresh: true);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // get register details and update the list element at index:

//   Future<void> getRegisterContestDetail() async {
//     try {
//       debugPrint('details are fetching:');
//       // loading only happends on the desired page: handling locally
//       final id = selectedRegister?.contest.id;
//       if (id == null) {
//         throw Exception('selectedRegister is null');
//       }
//       final responseBody = await ContestRepository.getContestDetail(id: id);
//       final data = await jsonDecode(responseBody);
//       final registered = RegisterDetailModel.fromJson(
//         data as Map<String, dynamic>,
//       );

//       // debug
//       final index =
//           state.registerIdMap[registered
//               .contest
//               .id]; // need to add items to when refresh or silent refesh:
//       if (index == null) {
//         throw Exception(
//           'Map index is null while updating the register details',
//         );
//       }

//       setSelectedRegister(registered);
//       state = state.copyWith(
//         registered: [...state.registered]..[index] = registered,
//       );

//       // state.registered[index] = register;
//       // updating that contest with update data like leaderboard or result or sumbit status:
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // also call the join contest and update the state of contest:
//   Future<String> joinContest() async {
//     try {
//       final id = selectedRegister?.contest.id;
//       if (id == null) {
//         throw Exception('selectedRegister is null');
//       }
//       final responseBody = await ContestRepository.patchJoinContest(id: id);
//       // TODO update contest model in registered contest:
//       final success = await jsonDecode(responseBody);
//       return 'Successfull! Please Continue ';
//     } catch (e) {
//       rethrow;
//     }
//   }

//   //  calling with to update the state of contest: in registers:
//   Future<String> submitContest({required String id}) async {
//     try {
//       final responseBody = await ContestRepository.postContestSubmit(
//         id: selectedRegister!.contest.id,
//       );
//       final success = await jsonDecode(responseBody)['detail'];
//       return success ?? 'Contest Submission Successful';
//     } catch (e) {
//       debugPrint(e.toString());
//       rethrow;
//     }
//   }

//   // get result from map again used to update only result:

//   // getPersonal result:
//   Future<void> getPersonalResult({bool refresh = false}) async {
//     try {
//       final userId = ref.read(authNotifierProvider).user?.id;

//       final id = selectedRegister?.contest.id;
//       final index = state.registerIdMap[id]; //might need attention

//       if (id == null || userId == null || index == null) {
//         throw Exception('Oops Personal Result exception');
//       }

//       if (!refresh) {
//         state = state.copyWith(
//           registered: [...state.registered]
//             ..[index] = state.registered[index].copyWith(
//               resultModel: AsyncLoading(),
//             ),
//         );
//       }
//       final responseBody = await ContestRepository.getContestResult(
//         id: id,
//         userId: userId,
//       );
//       final Map<String, dynamic> data = await jsonDecode(responseBody);
//       final result = RResultModel.fromJson(data);
//       // update the state:
//       state = state.copyWith(
//         registered: [...state.registered]
//           ..[index] = state.registered[index].copyWith(
//             resultModel: AsyncData(result),
//           ),
//       );

//       // use in statemanagment:
//       selectedRegister = state.registered[index];
//       return;
//     } on Exception {
//       throw 'Something went wrong';
//     } catch (e, st) {
//       //auth user result saving in state:
//       final id = selectedRegister?.contest.id;

//       final index = state.registerIdMap[id];
//       if (id == null || index == null) {
//         throw Exception('Something went wrong');
//       }
//       state = state.copyWith(
//         registered: [...state.registered]
//           ..[index] = state.registered[index].copyWith(
//             resultModel: AsyncError(e, st),
//           ),
//       );
//       state.registered[index] = state.registered[index].copyWith(
//         resultModel: AsyncError(e, st),
//       );
//       // use in statemanagment:
//       selectedRegister = state.registered[index];

//       rethrow;
//     }
//   }

//   Future<RResultModel> getResult({required String inputUserId}) async {
//     try {
//       final id = selectedRegister?.contest.id;
//       if (id == null) {
//         throw Exception('Oops! get result Exception');
//       }
//       final responseBody = await ContestRepository.getContestResult(
//         id: id,
//         userId: inputUserId,
//       );
//       final Map<String, dynamic> data = await jsonDecode(responseBody);
//       final result = RResultModel.fromJson(data);

//       return result;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   //get leaderboard and update registerdetialmodel :
//   Future<(List<LeaderboardModel> leaderboard, bool hasNext)>
//   getLeaderboardList({
//     required int offset,
//     int limit = 30,
//     bool refresh = false,
//   }) async {
//     try {
//       // Simulate when to stop (after 150 total items)
//       final total = 100;

//       //set offset to zero if refresh is called:
//       if (refresh) {
//         offset = 0;
//       }

//       final responseBody = await ContestRepository.getContestLeaderboard(
//         id: selectedRegister!.contest.id,
//         offset: offset,
//       );
//       final response = await jsonDecode(responseBody);
//       // update in state for future uses and make sure to call it if available in pages:
//       final newItems =
//           (response['data'] as List)
//               .map((e) => LeaderboardModel.fromJson(e))
//               .toList();

//       // only updating state
//       if (refresh) {
//         // needed to optimize to avoid multiple state changes:
//         offset = 0;
//         //this only clear the available leaderboardData:
//         // refreshing refresh the whole previously stored list:
//         final index = getCurrentRegisterIndex();

//         state = state.copyWith(
//           registered: [...state.registered]
//             ..[index] = state.registered[index].copyWith(
//               leaderboard: <LeaderboardModel>[],
//               leaderboardHasNext: false,
//             ), // Don't assign null else this will override by the previous value:
//         );
//         //Update the selected register:
//         setSelectedRegister(state.registered[index]);
//       }

//       final index = getCurrentRegisterIndex();
//       final initialLeaderlist = state.registered[index].leaderboard;
//       // Updating the state for the avoiding server fetching:
//       state = state.copyWith(
//         registered: [...state.registered]
//           ..[index] = state.registered[index].copyWith(
//             leaderboard: [...?initialLeaderlist, ...newItems],
//             leaderboardHasNext: response['has_next'] as bool,
//           ),
//       );
//       //Update the selected register:
//       setSelectedRegister(state.registered[index]);
//       return (newItems, response['has_next'] as bool);
//     } catch (e) {
//       debugPrint('oops something if off');
//       throw 'Something went wrong';
//     }
//   }

//   /// extras could be use save the  different user(s) results as list<resultModel>.
// }

// class RegisterState {
//   // tried to use them as minimal as possible. Decouple the widget with notifier. only required parameter will depends on notifier:
//   final bool loading;
//   final String? error;

//   // Data SECTION

//   // list of participated/registered question
//   final List<RegisterDetailModel> registered;
//   // registered page detail capture and update :
//   final Map<String, int> registerIdMap;

//   //NOTE:
//   // @deprecated setupTo manage global leaderboard might be scallable for handling as list grows

//   // NOTE when leaderboard and/or fetch with api state is preserver in registeredDetailModel for single source of leader and result without creating direct access. Need to first the registerdDetailModel (leaderboard,result-> must have a registered value)
//   //   // leaderboard also got leaderboard list[LeaderboardModel]

//   //   final List<LeaderboardModel>? leaderboard;
//   //   // create a map leaderboard.id to index.
//   //   final Map<String,int> leaderIdMap;

//   //   // after fetching result.  map leaderboard.id to result: fast and easy retrival with instead lookup:

//   const RegisterState({
//     required this.registered,
//     this.loading = false,
//     this.error,

//     this.registerIdMap = const {},
//   });

//   // copyWith for immutability
//   RegisterState copyWith({
//     // null represent data is not fetch if empty means there is no data avilable
//     List<RegisterDetailModel>? registered,
//     bool? loading,
//     String? error,
//     Map<String, int>? registerIdMap,
//   }) {
//     return RegisterState(
//       registered: registered ?? this.registered,
//       loading: loading ?? this.loading,
//       error: error ?? this.error,
//       registerIdMap: registerIdMap ?? this.registerIdMap,
//     );
//   }
// }
