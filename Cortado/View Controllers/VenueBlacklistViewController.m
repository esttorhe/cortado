#import <ReactiveCocoa/ReactiveCocoa.h>

#import "DataStore.h"
#import "FoursquareVenue.h"

#import "VenueBlacklistViewController.h"

static NSString * const HistoryIdentifier = @"HistoryCell";

@implementation VenueBlacklistViewController

- (id)initWithDataStore:(DataStore *)dataStore {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    _dataStore = dataStore;

    self.title = @"Ignored Coffee Shops";

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    [[RACSignal merge:@[RACObserve(self, dataStore.venueHistory), RACObserve(self, dataStore.blacklistedVenues)]]
        subscribeNext:^(id _) {
            [self.tableView reloadData];
        }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    if (indexPath.section == VenueBlacklistSectionHistory) {
        cell.accessoryView = nil;

        if (self.dataStore.venueHistory.count == 0) {
            cell.textLabel.text = @"You haven't been to any coffee shops yet.";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            FoursquareVenue *venue = self.dataStore.venueHistory[indexPath.row];
            cell.textLabel.text = venue.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", venue.address, venue.crossStreet];
        }
    } else if (indexPath.section == VenueBlacklistSectionBlacklisted) {
        cell.accessoryView = nil;

        FoursquareVenue *venue = self.dataStore.blacklistedVenues[indexPath.row];
        cell.textLabel.text = venue.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", venue.address, venue.crossStreet];
    } else if (indexPath.section == VenueBlacklistSectionStarbucks) {
        cell.textLabel.text = @"Ignore All Starbucks";

        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.on = self.dataStore.ignoreAllStarbucks;
        [toggle addTarget:self action:@selector(didChangeStarbucksToggle:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == VenueBlacklistSectionHistory) {
        if (self.dataStore.venueHistory.count == 0) return;

        FoursquareVenue *venue = self.dataStore.venueHistory[indexPath.row];
        NSString *message = [NSString stringWithFormat:@"By ignoring %@, it won't send you push notifications when you are near there.", venue.name];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Ignore Venue?"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"No Thanks"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action) {}]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ignore"
                   style:UIAlertActionStyleDestructive
                 handler:^(UIAlertAction *action) {
                     [self.dataStore blacklistVenue:venue];
                 }]];

        [self presentViewController:alert animated:YES completion:nil];
    } else if (indexPath.section == VenueBlacklistSectionBlacklisted) {
        FoursquareVenue *venue = self.dataStore.blacklistedVenues[indexPath.row];
        NSString *message = [NSString stringWithFormat:@"If you are near %@, you will receive push notifications again.", venue.name];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Restore Venue?"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"No Thanks"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action) {}]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Restore"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
                                                    [self.dataStore unblacklistVenue:venue];
                                                }]];

        [self presentViewController:alert animated:YES completion:nil];
    } else if (indexPath.section == VenueBlacklistSectionStarbucks) {
        return;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return VenueBlacklistSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == VenueBlacklistSectionBlacklisted) {
        return self.dataStore.blacklistedVenues.count;
    } else if (section == VenueBlacklistSectionHistory) {
        if (self.dataStore.venueHistory.count == 0) {
            return 1;
        }
        return self.dataStore.venueHistory.count;
    } else if (section == VenueBlacklistSectionStarbucks) {
        return 1;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:HistoryIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:HistoryIdentifier];
        cell.textLabel.numberOfLines = 0;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == VenueBlacklistSectionHistory) {
        return @"Tap to ignore. Ignored coffee shops won't trigger push notifications.";
    } else if (section == VenueBlacklistSectionBlacklisted) {
        if ([self tableView:self.tableView numberOfRowsInSection:VenueBlacklistSectionBlacklisted] > 0) {
            return @"Ignored coffee shops";
        }
    } else if (section == VenueBlacklistSectionStarbucks) {
        return @"Because Starbucks is so common, it can be a common source of false positives.";
    }
    return nil;
}

#pragma mark -

- (void)didChangeStarbucksToggle:(UISwitch *)toggle {
    self.dataStore.ignoreAllStarbucks = toggle.on;
}

@end
