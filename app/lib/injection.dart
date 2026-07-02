import 'package:app/core/network/api_client.dart';
import 'package:app/core/local_api/local_api_server.dart';
import 'package:app/features/configuration/data/datasources/configuration_local_datasource.dart';
import 'package:app/features/configuration/data/datasources/configuration_local_datasource_impl.dart';
import 'package:app/features/configuration/data/datasources/printer_datasource.dart';
import 'package:app/features/configuration/data/datasources/thermal_printer_datasource_impl.dart';
import 'package:app/features/configuration/data/repositories/printer_configuration_repository_impl.dart';
import 'package:app/features/configuration/data/repositories/receipt_configuration_repository_impl.dart';
import 'package:app/features/configuration/domain/repositories/printer_configuration_repository.dart';
import 'package:app/features/configuration/domain/repositories/receipt_configuration_repository.dart';
import 'package:app/features/configuration/domain/services/receipt_generator.dart';
import 'package:app/features/configuration/domain/usecases/check_printer_connection_usecase.dart';
import 'package:app/features/configuration/domain/usecases/clear_printer_configuration_usecase.dart';
import 'package:app/features/configuration/domain/usecases/disconnect_printer_usecase.dart';
import 'package:app/features/configuration/domain/usecases/discover_printers_usecase.dart';
import 'package:app/features/configuration/domain/usecases/get_printer_configuration_usecase.dart';
import 'package:app/features/configuration/domain/usecases/get_receipt_settings_usecase.dart';
import 'package:app/features/configuration/domain/usecases/print_receipt_usecase.dart';
import 'package:app/features/configuration/domain/usecases/save_printer_configuration_usecase.dart';
import 'package:app/features/configuration/domain/usecases/save_receipt_settings_usecase.dart';
import 'package:app/features/configuration/presentation/bloc/printer_configuration_cubit.dart';
import 'package:app/features/configuration/presentation/bloc/receipt_configuration_cubit.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource_impl.dart';
import 'package:app/features/auth/data/datasources/auth_local_api_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_local_api_datasource_impl.dart';
import 'package:app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/usecases/get_session_usecase.dart';
import 'package:app/features/auth/domain/usecases/has_local_users_usecase.dart';
import 'package:app/features/auth/domain/usecases/login_usecase.dart';
import 'package:app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:app/features/auth/domain/usecases/create_initial_admin_usecase.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/products/data/datasources/products_local_api_datasource.dart';
import 'package:app/features/products/data/datasources/products_local_api_datasource_impl.dart';
import 'package:app/features/products/data/repositories/products_repository_impl.dart';
import 'package:app/features/products/domain/repositories/products_repository.dart';
import 'package:app/features/products/domain/usecases/create_item_usecase.dart';
import 'package:app/features/products/domain/usecases/get_categories_usecase.dart';
import 'package:app/features/products/domain/usecases/get_itbis_rates_usecase.dart';
import 'package:app/features/products/domain/usecases/get_items_usecase.dart';
import 'package:app/features/products/domain/usecases/update_item_usecase.dart';
import 'package:app/features/products/presentation/bloc/products_bloc.dart';
import 'package:app/features/clients/data/datasources/clients_local_api_datasource.dart';
import 'package:app/features/clients/data/datasources/clients_local_api_datasource_impl.dart';
import 'package:app/features/clients/data/repositories/clients_repository_impl.dart';
import 'package:app/features/clients/domain/repositories/clients_repository.dart';
import 'package:app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:app/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:app/features/clients/domain/usecases/update_client_usecase.dart';
import 'package:app/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:app/features/bills/data/datasources/bills_local_api_datasource.dart';
import 'package:app/features/bills/data/datasources/bills_local_api_datasource_impl.dart';
import 'package:app/features/bills/data/repositories/bills_repository_impl.dart';
import 'package:app/features/bills/domain/repositories/bills_repository.dart';
import 'package:app/features/bills/domain/usecases/get_bills_usecase.dart';
import 'package:app/features/bills/domain/usecases/get_bill_by_id_usecase.dart';
import 'package:app/features/bills/domain/usecases/get_bill_by_public_id_usecase.dart';
import 'package:app/features/bills/domain/usecases/create_sale_bill_usecase.dart';
import 'package:app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:app/features/reports/data/datasources/reports_local_api_datasource.dart';
import 'package:app/features/reports/data/datasources/reports_local_api_datasource_impl.dart';
import 'package:app/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:app/features/reports/domain/repositories/reports_repository.dart';
import 'package:app/features/reports/domain/usecases/get_bill_report_usecase.dart';
import 'package:app/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:app/features/sales/presentation/bloc/sale_bloc.dart';
import 'package:app/features/users/data/datasources/users_local_api_datasource.dart';
import 'package:app/features/users/data/datasources/users_local_api_datasource_impl.dart';
import 'package:app/features/users/data/repositories/local_users_repository_impl.dart';
import 'package:app/features/users/domain/repositories/local_users_repository.dart';
import 'package:app/features/users/domain/usecases/create_local_user_usecase.dart';
import 'package:app/features/users/domain/usecases/delete_local_user_usecase.dart';
import 'package:app/features/users/domain/usecases/get_local_users_usecase.dart';
import 'package:app/features/users/domain/usecases/update_local_user_usecase.dart';
import 'package:app/features/users/presentation/bloc/users_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/thermal_printer.dart';

final GetIt sl = GetIt.instance;

Future<void> initInjection({required LocalApiServer localApiServer}) async {
  final sharedPreferences = await SharedPreferences.getInstance();

  // Core
  sl.registerLazySingleton<LocalApiServer>(() => localApiServer);
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<PrinterManager>(() => PrinterManager.instance);
  sl.registerLazySingleton<Dio>(
    () => createApiClient(localApiServer: localApiServer),
  );

  // Auth - Data
  sl.registerLazySingleton<AuthLocalApiDataSource>(
    () => AuthLocalApiDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localApi: sl<AuthLocalApiDataSource>(),
      local: sl<AuthLocalDataSource>(),
    ),
  );

  // Auth - Domain (use cases)
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetSessionUseCase>(
    () => GetSessionUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<HasLocalUsersUseCase>(
    () => HasLocalUsersUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<CreateInitialAdminUseCase>(
    () => CreateInitialAdminUseCase(sl<AuthRepository>()),
  );

  // Auth - Presentation (BLoC as singleton for router redirect)
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getSessionUseCase: sl<GetSessionUseCase>(),
      hasLocalUsersUseCase: sl<HasLocalUsersUseCase>(),
      createInitialAdminUseCase: sl<CreateInitialAdminUseCase>(),
    ),
  );

  // Products - Data
  sl.registerLazySingleton<ProductsLocalApiDataSource>(
    () => ProductsLocalApiDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ProductsRepository>(
    () => ProductsRepositoryImpl(sl<ProductsLocalApiDataSource>()),
  );

  // Products - Domain (use cases)
  sl.registerLazySingleton<GetItemsUseCase>(
    () => GetItemsUseCase(sl<ProductsRepository>()),
  );
  sl.registerLazySingleton<GetCategoriesUseCase>(
    () => GetCategoriesUseCase(sl<ProductsRepository>()),
  );
  sl.registerLazySingleton<GetItbisRatesUseCase>(
    () => GetItbisRatesUseCase(sl<ProductsRepository>()),
  );
  sl.registerLazySingleton<CreateItemUseCase>(
    () => CreateItemUseCase(sl<ProductsRepository>()),
  );
  sl.registerLazySingleton<UpdateItemUseCase>(
    () => UpdateItemUseCase(sl<ProductsRepository>()),
  );

  // Products - Presentation
  sl.registerLazySingleton<ProductsBloc>(
    () => ProductsBloc(
      getItemsUseCase: sl<GetItemsUseCase>(),
      getCategoriesUseCase: sl<GetCategoriesUseCase>(),
      getItbisRatesUseCase: sl<GetItbisRatesUseCase>(),
      createItemUseCase: sl<CreateItemUseCase>(),
      updateItemUseCase: sl<UpdateItemUseCase>(),
    ),
  );

  // Clients - Data
  sl.registerLazySingleton<ClientsLocalApiDataSource>(
    () => ClientsLocalApiDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ClientsRepository>(
    () => ClientsRepositoryImpl(sl<ClientsLocalApiDataSource>()),
  );

  // Clients - Domain (use cases)
  sl.registerLazySingleton<GetClientsUseCase>(
    () => GetClientsUseCase(sl<ClientsRepository>()),
  );
  sl.registerLazySingleton<CreateClientUseCase>(
    () => CreateClientUseCase(sl<ClientsRepository>()),
  );
  sl.registerLazySingleton<UpdateClientUseCase>(
    () => UpdateClientUseCase(sl<ClientsRepository>()),
  );

  // Clients - Presentation
  sl.registerFactory<ClientsBloc>(
    () => ClientsBloc(
      getClientsUseCase: sl<GetClientsUseCase>(),
      createClientUseCase: sl<CreateClientUseCase>(),
      updateClientUseCase: sl<UpdateClientUseCase>(),
    ),
  );

  // Bills - Data
  sl.registerLazySingleton<BillsLocalApiDataSource>(
    () => BillsLocalApiDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<BillsRepository>(
    () => BillsRepositoryImpl(sl<BillsLocalApiDataSource>()),
  );

  // Bills - Domain (use cases)
  sl.registerLazySingleton<GetBillsUseCase>(
    () => GetBillsUseCase(sl<BillsRepository>()),
  );
  sl.registerLazySingleton<GetBillByIdUseCase>(
    () => GetBillByIdUseCase(sl<BillsRepository>()),
  );
  sl.registerLazySingleton<GetBillByPublicIdUseCase>(
    () => GetBillByPublicIdUseCase(sl<BillsRepository>()),
  );
  sl.registerLazySingleton<CreateSaleBillUseCase>(
    () => CreateSaleBillUseCase(sl<BillsRepository>()),
  );

  // Bills - Presentation
  sl.registerFactory<BillsBloc>(
    () => BillsBloc(
      getBillsUseCase: sl<GetBillsUseCase>(),
      getBillByIdUseCase: sl<GetBillByIdUseCase>(),
      getBillByPublicIdUseCase: sl<GetBillByPublicIdUseCase>(),
    ),
  );

  // Reports - Data
  sl.registerLazySingleton<ReportsLocalApiDataSource>(
    () => ReportsLocalApiDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(sl<ReportsLocalApiDataSource>()),
  );

  // Reports - Domain
  sl.registerLazySingleton<GetBillReportUseCase>(
    () => GetBillReportUseCase(sl<ReportsRepository>()),
  );

  // Reports - Presentation
  sl.registerFactory<ReportsBloc>(
    () => ReportsBloc(getBillReportUseCase: sl<GetBillReportUseCase>()),
  );

  // Sales - Presentation
  sl.registerFactory<SaleBloc>(
    () => SaleBloc(
      getItemsUseCase: sl<GetItemsUseCase>(),
      createSaleBillUseCase: sl<CreateSaleBillUseCase>(),
      printReceiptUseCase: sl<PrintReceiptUseCase>(),
    ),
  );

  // Configuration - Data
  sl.registerLazySingleton<ConfigurationLocalDataSource>(
    () => ConfigurationLocalDataSourceImpl(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<PrinterDataSource>(
    () => ThermalPrinterDataSourceImpl(sl<PrinterManager>()),
  );
  sl.registerLazySingleton<PrinterConfigurationRepository>(
    () => PrinterConfigurationRepositoryImpl(
      localDataSource: sl<ConfigurationLocalDataSource>(),
      printerDataSource: sl<PrinterDataSource>(),
    ),
  );
  sl.registerLazySingleton<ReceiptConfigurationRepository>(
    () => ReceiptConfigurationRepositoryImpl(
      sl<ConfigurationLocalDataSource>(),
    ),
  );
  sl.registerLazySingleton<ReceiptGenerator>(() => ReceiptGenerator());

  // Configuration - Domain
  sl.registerLazySingleton<GetPrinterConfigurationUseCase>(
    () => GetPrinterConfigurationUseCase(
      sl<PrinterConfigurationRepository>(),
    ),
  );
  sl.registerLazySingleton<DiscoverPrintersUseCase>(
    () => DiscoverPrintersUseCase(sl<PrinterConfigurationRepository>()),
  );
  sl.registerLazySingleton<SavePrinterConfigurationUseCase>(
    () => SavePrinterConfigurationUseCase(
      sl<PrinterConfigurationRepository>(),
    ),
  );
  sl.registerLazySingleton<CheckPrinterConnectionUseCase>(
    () => CheckPrinterConnectionUseCase(
      sl<PrinterConfigurationRepository>(),
    ),
  );
  sl.registerLazySingleton<DisconnectPrinterUseCase>(
    () => DisconnectPrinterUseCase(sl<PrinterConfigurationRepository>()),
  );
  sl.registerLazySingleton<ClearPrinterConfigurationUseCase>(
    () => ClearPrinterConfigurationUseCase(
      sl<PrinterConfigurationRepository>(),
    ),
  );
  sl.registerLazySingleton<GetReceiptSettingsUseCase>(
    () => GetReceiptSettingsUseCase(sl<ReceiptConfigurationRepository>()),
  );
  sl.registerLazySingleton<SaveReceiptSettingsUseCase>(
    () => SaveReceiptSettingsUseCase(sl<ReceiptConfigurationRepository>()),
  );
  sl.registerLazySingleton<PrintReceiptUseCase>(
    () => PrintReceiptUseCase(
      printerRepository: sl<PrinterConfigurationRepository>(),
      receiptRepository: sl<ReceiptConfigurationRepository>(),
      receiptGenerator: sl<ReceiptGenerator>(),
    ),
  );

  // Configuration - Presentation
  sl.registerFactory<PrinterConfigurationCubit>(
    () => PrinterConfigurationCubit(
      getPrinterConfigurationUseCase: sl<GetPrinterConfigurationUseCase>(),
      discoverPrintersUseCase: sl<DiscoverPrintersUseCase>(),
      savePrinterConfigurationUseCase: sl<SavePrinterConfigurationUseCase>(),
      checkPrinterConnectionUseCase: sl<CheckPrinterConnectionUseCase>(),
      disconnectPrinterUseCase: sl<DisconnectPrinterUseCase>(),
      clearPrinterConfigurationUseCase:
          sl<ClearPrinterConfigurationUseCase>(),
    ),
  );
  sl.registerFactory<ReceiptConfigurationCubit>(
    () => ReceiptConfigurationCubit(
      getReceiptSettingsUseCase: sl<GetReceiptSettingsUseCase>(),
      saveReceiptSettingsUseCase: sl<SaveReceiptSettingsUseCase>(),
    ),
  );

  // Users - Data
  sl.registerLazySingleton<UsersLocalApiDataSource>(
    () => UsersLocalApiDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<LocalUsersRepository>(
    () => LocalUsersRepositoryImpl(
      localApi: sl<UsersLocalApiDataSource>(),
      authLocalDataSource: sl<AuthLocalDataSource>(),
    ),
  );

  // Users - Domain
  sl.registerLazySingleton<GetLocalUsersUseCase>(
    () => GetLocalUsersUseCase(sl<LocalUsersRepository>()),
  );
  sl.registerLazySingleton<CreateLocalUserUseCase>(
    () => CreateLocalUserUseCase(sl<LocalUsersRepository>()),
  );
  sl.registerLazySingleton<UpdateLocalUserUseCase>(
    () => UpdateLocalUserUseCase(sl<LocalUsersRepository>()),
  );
  sl.registerLazySingleton<DeleteLocalUserUseCase>(
    () => DeleteLocalUserUseCase(sl<LocalUsersRepository>()),
  );

  // Users - Presentation
  sl.registerFactory<UsersBloc>(
    () => UsersBloc(
      getLocalUsersUseCase: sl<GetLocalUsersUseCase>(),
      createLocalUserUseCase: sl<CreateLocalUserUseCase>(),
      updateLocalUserUseCase: sl<UpdateLocalUserUseCase>(),
      deleteLocalUserUseCase: sl<DeleteLocalUserUseCase>(),
    ),
  );
}
