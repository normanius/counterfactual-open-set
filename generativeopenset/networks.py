import os
import traceback
import network_definitions
import torch
from torch import optim
from torch import nn
from imutil import ensure_directory_exists

def print_summary(network, image_size, label, print_error=True):
    try:
        from torchinfo import summary
    except ModuleNotFoundError:
        print("Warning: Install package 'torchinfo' to show network info.")
        return

    print("="*80)
    print(label)
    print("="*80)
    print()
    try:
        summary(network, image_size)
    except RuntimeError as e:
        print("Failed to generate summary for input size:", image_size)
        print()
        print(traceback.format_exc())
    print()

def build_networks(num_classes, epoch=None, image_size=32,
                   latent_size=10, batch_size=64, print_networks=True,
                   **options):
    networks = {}

    EncoderClass = network_definitions.encoder32
    networks['encoder'] = EncoderClass(image_size=image_size,
                                       latent_size=latent_size,
                                       batch_size=batch_size)

    GeneratorClass = network_definitions.generator32
    networks['generator'] = GeneratorClass(image_size=image_size,
                                           latent_size=latent_size,
                                           batch_size=batch_size)

    DiscrimClass = network_definitions.multiclassDiscriminator32
    networks['discriminator'] = DiscrimClass(num_classes=num_classes,
                                             image_size=image_size,
                                             latent_size=latent_size,
                                             batch_size=batch_size)

    ClassifierClass = network_definitions.classifier32
    networks['classifier_k'] = ClassifierClass(num_classes=num_classes,
                                               image_size=image_size,
                                               latent_size=latent_size,
                                               batch_size=batch_size)
    networks['classifier_kplusone'] = ClassifierClass(num_classes=num_classes,
                                                      image_size=image_size,
                                                      latent_size=latent_size,
                                                      batch_size=batch_size)


    if print_networks:
        img_size = (batch_size, 3, image_size, image_size)
        print_summary(networks["encoder"], img_size, label="Encoder")
        print_summary(networks["generator"], (batch_size, latent_size,), label="Generator")
        print_summary(networks["discriminator"], img_size, label="Discriminator")
        print_summary(networks["classifier_k"], img_size, label="Classifier k")
        print_summary(networks["classifier_kplusone"], img_size, label="Classifier k+1")
        print()


    for net_name in networks:
        pth = get_pth_by_epoch(options['result_dir'], net_name, epoch)
        if pth:
            print("Loading {} from checkpoint {}".format(net_name, pth))
            networks[net_name].load_state_dict(torch.load(pth))
        else:
            print("Using randomly-initialized weights for {}".format(net_name))
    return networks


def get_network_class(name):
    if type(name) is not str or not hasattr(network_definitions, name):
        print("Error: could not construct network '{}'".format(name))
        print("Available networks are:")
        for net_name in dir(network_definitions):
            classobj = getattr(network_definitions, net_name)
            if type(classobj) is type and issubclass(classobj, nn.Module):
                print('\t' + net_name)
        exit()
    return getattr(network_definitions, name)


def save_networks(networks, epoch, result_dir):
    for name in networks:
        weights = networks[name].state_dict()
        filename = '{}/checkpoints/{}_epoch_{:04d}.pth'.format(result_dir, name, epoch)
        ensure_directory_exists(filename)
        torch.save(weights, filename)


def get_optimizers(networks, lr=.0001, beta1=.5, beta2=.999, weight_decay=.0, finetune=False, **options):
    optimizers = {}
    if finetune:
        lr /= 10
        print("Fine-tuning mode activated, dropping learning rate to {}".format(lr))
    for name in networks:
        net = networks[name]
        optimizers[name] = optim.Adam(net.parameters(), lr=lr, betas=(beta1, beta2), weight_decay=weight_decay)
    return optimizers


def get_pth_by_epoch(result_dir, name, epoch=None):
    checkpoint_path = os.path.join(result_dir, 'checkpoints/')
    ensure_directory_exists(checkpoint_path)
    files = os.listdir(checkpoint_path)
    suffix = '.pth'
    if epoch is not None:
        suffix = 'epoch_{:04d}.pth'.format(epoch)
    files = [f for f in files if '{}_epoch'.format(name) in f]
    if not files:
        return None
    files = [os.path.join(checkpoint_path, fn) for fn in files]
    files.sort(key=lambda x: os.stat(x).st_mtime)
    return files[-1]
